@tool
extends Node


signal file_opened(file: Gvint.EditorFile)
signal file_closing(file: Gvint.EditorFile)
signal file_index_closed(index: int)
signal file_index_moved(from: int, to: int)
signal current_file_changed(file: Gvint.EditorFile)
signal all_files_closed

const STATE_SAVEFILE_PATH = "res://addons/GViNT/Editor/open_files.json"

var plugin: EditorPlugin
var open_files := []
var current_file: Gvint.EditorFile = null:
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
	var state_dict := Gvint.Utils.read_json_dict(STATE_SAVEFILE_PATH)
	if state_dict.is_empty():
		return
	for file_path in state_dict.open_files:
		if FileAccess.file_exists(file_path):
			open_file_and_set_current(file_path)
	if open_files and current_file.manager_index != 0:
		set_file_at_index_as_selected(0)


func serialize_state() -> void:
	var state = {
		"open_files": [],
	}
	for file in open_files:
		if file.file_path:
			state.open_files.append(file.file_path)
	Gvint.Utils.write_json(STATE_SAVEFILE_PATH, state)


func set_current_file(value: Gvint.EditorFile) -> void:
	current_file = value
	current_file_changed.emit(current_file)


func get_open_file_index(file: Gvint.EditorFile) -> int:
	return open_files.find(file)


func get_open_file_with_path(file_path: String) -> Gvint.EditorFile:
	for file in open_files:
		if file.file_path == file_path:
			return file
	return null


func set_file_at_index_as_selected(index: int) -> void:
	current_file = open_files[index]


func create_new_file_and_set_current() -> void:
	var new_file := Gvint.EditorFile.new()
	_add_open_file(new_file)


func open_file_and_set_current(file_path: String) -> void:
	var opened_file := get_open_file_with_path(file_path)
	
	if opened_file:
		current_file = opened_file
		return
	
	opened_file = Gvint.EditorFile.load_file(file_path)
	
	_add_open_file(opened_file)


func save_current_file() -> void:
	if not current_file:
		return
	if current_file.file_path:
		current_file.save()
	else:
		$SaveAsFileDialog.show()


func save_and_close_current_file() -> void:
	if not current_file:
		return
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
	close_current_file_without_saving()


func save_current_file_as(file_path: String) -> void:
	if not current_file:
		return
	if not current_file.file_path:
		# if a file with the specified path is already open,
		# make it an "Untitled" file instead to prevent having the same
		# file open twice
		var open_file_with_this_path = get_open_file_with_path(file_path)
		if open_file_with_this_path:
			open_file_with_this_path.filename = "Untitled"
			open_file_with_this_path.has_unsaved_changes = true
			open_file_with_this_path.file_path = ""
		
		serialize_state()
	current_file.save_as(file_path)


func prompt_save_or_close_current_file() -> void:
	if not current_file:
		return
	if current_file.has_unsaved_changes:
		$SaveChangesDialog.show()
	else:
		close_current_file_without_saving()


func close_current_file_without_saving() -> void:
	if not current_file:
		return
	var closed_file_index := _close_file(current_file)
	
	if open_files.size() == 0:
		current_file = null
		all_files_closed.emit()
	else:
		if closed_file_index == 0:
			set_file_at_index_as_selected(0)
		else:
			set_file_at_index_as_selected(closed_file_index - 1)


func move_current_file_up() -> void:
	if not current_file:
		return
	if current_file.manager_index == 0:
		return
	var swapped_from = current_file.manager_index
	var swapped_to = swapped_from - 1
	_swap_files(swapped_from, swapped_to)
	file_index_moved.emit(swapped_from, swapped_to)


func move_current_file_down() -> void:
	if not current_file:
		return
	if current_file.manager_index == (open_files.size() - 1):
		return
	var swapped_from = current_file.manager_index
	var swapped_to = swapped_from + 1
	_swap_files(swapped_from, swapped_to)
	file_index_moved.emit(swapped_from, swapped_to)


func move_current_file(to_index: int):
	if not current_file:
		return
	var from_index = current_file.manager_index
	if to_index > from_index:
		for index in range(from_index, to_index):
			_swap_files(index, index + 1)
	elif to_index < from_index:
		for index in range(from_index, to_index, -1):
			_swap_files(index, index - 1)
	file_index_moved.emit(from_index, to_index)


func _swap_files(index_a: int, index_b: int) -> void:
	var file_a = open_files[index_a]
	var file_b = open_files[index_b]
	file_a.manager_index = index_b
	file_b.manager_index = index_a
	open_files[index_a] = file_b
	open_files[index_b] = file_a


func _add_open_file(file: Gvint.EditorFile) -> void:
	file.manager_index = open_files.size()
	file.parse_result = Gvint.Parser.parse_text(file.get_content())
	if file.parse_result.errors.is_empty():
		file.last_successful_parse_result = file.parse_result
	open_files.append(file)
	file_opened.emit(file)
	current_file = file


func _close_file(file: Gvint.EditorFile) -> int:
	file_closing.emit(file)
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


func _on_file_opened_or_closing(file: Gvint.EditorFile) -> void:
	if file.file_path:
		serialize_state.call_deferred()
