@tool
extends Node


signal file_opened(file: EditorGvintFileData)
signal file_closing(file: EditorGvintFileData)
signal file_index_closed(index: int)
signal current_file_changed(file: EditorGvintFileData)
signal all_files_closed

const STATE_SAVEFILE_PATH = "res://addons/GViNT/Editor/persistent_state.json"

var plugin: EditorPlugin
var open_files := []
var current_file: EditorGvintFileData = null:
	set = set_current_file


func _ready() -> void:
	if plugin and Engine.is_editor_hint():
		EditorInterface.get_resource_filesystem().filesystem_changed\
				.connect(_on_editor_filesystem_changed)
	if plugin or not Engine.is_editor_hint():
		restore_state()
		serialize_state()
		file_opened.connect(_on_file_opened_or_closing)
		file_closing.connect(_on_file_opened_or_closing)


func restore_state() -> void:
	var serialized_state = FileAccess.get_file_as_string(STATE_SAVEFILE_PATH)
	var state_dict: Dictionary = JSON.parse_string(serialized_state)
	for file_path in state_dict.open_files:
		if FileAccess.file_exists(file_path):
			open_file_and_set_current(file_path)
	if open_files:
		set_file_at_index_as_selected(0)


func serialize_state() -> void:
	# for some reason, when this function is called when the editor is closed,
	# eg from _exit_tree, it serializes the open_files array as empty.
	# so instead, this should be called every time the file list is updated
	# (if the update is concerning a file with a set file path;
	# "Untitled" files are ignored)
	var state_dict = {
		"open_files": [],
	}
	for file in open_files:
		if file.file_path:
			state_dict.open_files.append(file.file_path)
	var serialized_state := JSON.stringify(state_dict)
	EditorGvintUtils.write_file(STATE_SAVEFILE_PATH, serialized_state)


func set_current_file(value: EditorGvintFileData) -> void:
	current_file = value
	current_file_changed.emit(current_file)


func get_open_file_index(file: EditorGvintFileData) -> int:
	return open_files.find(file)


func get_open_file_with_path(file_path: String) -> EditorGvintFileData:
	for file in open_files:
		if file.file_path == file_path:
			return file
	return null


func set_file_at_index_as_selected(index: int) -> void:
	current_file = open_files[index]


func create_new_file_and_set_current() -> void:
	var new_file := EditorGvintFileData.new()
	_add_open_file(new_file)


func open_file_and_set_current(file_path: String) -> void:
	var opened_file := get_open_file_with_path(file_path)
	
	if opened_file:
		current_file = opened_file
		return
	
	opened_file = EditorGvintFileData.load_file(file_path)
	
	_add_open_file(opened_file)


func save_current_file() -> void:
	assert(current_file)
	if current_file.file_path:
		current_file.save()
	else:
		$SaveAsFileDialog.show()


func save_and_close_current_file() -> void:
	assert(current_file)
	if current_file.file_path:
		current_file.save()
	else:
		$SaveAsAndCloseFileDialog.show()
		var save_path: String = \
				await $SaveAsAndCloseFileDialog.cancelled_or_file_selected
		var save_cancelled = (save_path == "")
		if not save_cancelled:
			var previously_opened_saved_file := get_open_file_with_path(save_path)
			if previously_opened_saved_file:
				previously_opened_saved_file.has_unsaved_changes = true
			current_file.file_path = save_path
			current_file.save()
	close_current_file()


func save_current_file_as(file_path: String) -> void:
	assert(current_file)
	if not current_file.file_path:
		# if a file with the specified path is already open,
		# make it an "Untitled" file instead to prevent having the same
		# file open twice
		var open_file_with_this_path = get_open_file_with_path(file_path)
		if open_file_with_this_path:
			open_file_with_this_path.filename = "Untitled"
			open_file_with_this_path.has_unsaved_changes = true
			open_file_with_this_path.file_path = ""
		
		current_file.file_path = file_path
		current_file.filename = file_path.split("/")[-1]
		current_file.has_unsaved_changes = false
		serialize_state()
	EditorGvintUtils.write_file(file_path, current_file.get_content())
	if file_path == current_file.file_path:
		current_file.modified_time = Time.get_unix_time_from_system()
		current_file.has_unsaved_changes = false


func prompt_save_or_close_current_file() -> void:
	if current_file.has_unsaved_changes:
		$SaveChangesDialog.show()
	else:
		close_current_file()


func close_current_file() -> void:
	var closed_file_index := _close_file(current_file)
	
	if open_files.size() == 0:
		current_file = null
		all_files_closed.emit()
	else:
		set_file_at_index_as_selected(closed_file_index - 1)


func _add_open_file(file: EditorGvintFileData) -> void:
	file.manager_index = open_files.size()
	open_files.append(file)
	file_opened.emit(file)
	current_file = file


func _close_file(file: EditorGvintFileData) -> int:
	file_closing.emit(file)
	file.closing.emit()
	var file_index: int = file.manager_index
	open_files.erase(file)
	for i in range(file_index, open_files.size()):
		open_files[i].manager_index -= 1
	file_index_closed.emit(file_index)
	file.free()
	return file_index


func _on_editor_filesystem_changed() -> void:
	for file in open_files:
		var file_path = file.file_path
		if not file_path:
			continue
		if not FileAccess.file_exists(file_path):
			file.file_path = ""
			file.filename = "Untitled"
			file.has_unsaved_changes = true
		elif FileAccess.get_modified_time(file_path) > file.modified_time:
			file.has_unsaved_changes = true


func _on_file_opened_or_closing(file: EditorGvintFileData) -> void:
	if file.file_path:
		serialize_state.call_deferred()
