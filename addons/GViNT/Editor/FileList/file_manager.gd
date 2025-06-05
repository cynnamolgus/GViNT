@tool
extends Node


signal file_opened(file: EditorGvintFileData)
signal file_index_closed(index: int)
signal current_file_changed(file: EditorGvintFileData)
signal all_files_closed

var open_files := []
var current_file: EditorGvintFileData = null:
	set = set_current_file


func _init() -> void:
	EditorInterface.get_resource_filesystem().\
		filesystem_changed.connect(_on_editor_filesystem_changed)


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
	
	var file_content := FileAccess.get_file_as_string(file_path)
	var filename = file_path.split("/")[-1]
	var file_content_lines := file_content.split("\n")
	
	opened_file = EditorGvintFileData.new()
	opened_file.filename = filename
	opened_file.file_path = file_path
	opened_file.content_lines = file_content_lines
	
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
		
		# if a file with the specified path is already open, close it
		# to prevent having the same file open twice
		var open_file_with_this_path = get_open_file_with_path(file_path)
		if open_file_with_this_path:
			_close_file(open_file_with_this_path)
		
		current_file.file_path = file_path
		current_file.filename = file_path.split("/")[-1]
		current_file.has_unsaved_changes = false
	EditorGvintUtils.write_file(file_path, current_file.get_content())
	if file_path == current_file.file_path:
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
	var file_index: int = file.manager_index
	open_files.erase(file)
	for i in range(file_index, open_files.size()):
		open_files[i].manager_index -= 1
	file.closing.emit()
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
