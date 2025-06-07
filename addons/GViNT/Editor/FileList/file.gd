@tool
extends Object


signal content_changed
signal filename_changed
signal modified_status_changed

enum Operations {
	SET_LINE,
	INSERT_LINES,
	REMOVE_LINES
}

var manager_index: int
var content_lines := PackedStringArray([""])
var file_path: String = ""
var modified_time: int
var filename: String = "Untitled":
	set(value):
		filename = value
		filename_changed.emit()
var has_unsaved_changes: bool = false:
	set(value):
		has_unsaved_changes = value
		modified_status_changed.emit()
var code_edit: Gvint.EditorCodeEdit

var _changes_queue := []


static func load_file(from_path: String) -> Gvint.EditorFile:
	var file := Gvint.EditorFile.new()
	
	file.filename = from_path.split("/")[-1]
	file.file_path = from_path
	file.content_lines = FileAccess.get_file_as_string(from_path).split("\n")
	file.modified_time = FileAccess.get_modified_time(from_path)
	
	return file


func _init() -> void:
	code_edit = Gvint.EditorCodeEdit.new()
	code_edit.file = self


func free() -> void:
	code_edit.queue_free()
	super.free()

func get_content() -> String:
	return "\n".join(content_lines)


func queue_set_line(index: int, text: String) -> void:
	has_unsaved_changes = true
	if not _changes_queue:
		_changes_queue.append([Operations.SET_LINE, index, text])
	else:
		var last_change = _changes_queue.back()
		if (
				last_change \
				and last_change[0] == Operations.SET_LINE \
				and last_change[1] == index
		):
			last_change[2] = text
		else:
			_changes_queue.append([Operations.SET_LINE, index, text])


func queue_insert_lines(at_index: int, lines: Array) -> void:
	has_unsaved_changes = true
	_changes_queue.append([Operations.INSERT_LINES, at_index, lines])


func queue_remove_lines(after_index: int, line_count: int) -> void:
	has_unsaved_changes = true
	_changes_queue.append([Operations.REMOVE_LINES, after_index, line_count])


func flush_changes_queue() -> void:
	for operation in _changes_queue:
		match operation[0]:
			Operations.SET_LINE:
				set_line(operation[1], operation[2])
			Operations.INSERT_LINES:
				insert_lines(operation[1], operation[2])
			Operations.REMOVE_LINES:
				remove_lines(operation[1], operation[2])
			_:
				assert(false, "invalid file change operation")
	_changes_queue.clear()


func set_line(index: int, text: String) -> void:
	assert(index < content_lines.size())
	content_lines[index] = text
	content_changed.emit()


func insert_lines(at_index: int, lines: Array) -> void:
	assert(at_index <= content_lines.size())
	assert(lines)
	var i = 0
	for line in lines:
		content_lines.insert(at_index + i, line)
		i += 1
	content_changed.emit()


func remove_lines(after_index: int, line_count: int) -> void:
	assert( (after_index + line_count) <= content_lines.size() )
	assert(line_count != 0)
	for i in range(line_count):
		content_lines.remove_at(after_index + 1)


func save() -> void:
	flush_changes_queue()
	Gvint.Utils.write_file(file_path, get_content())
	modified_time = int(Time.get_unix_time_from_system())
	has_unsaved_changes = false
	if Engine.is_editor_hint():
		EditorInterface.get_resource_filesystem().scan()


func save_as(save_path: String) -> void:
	flush_changes_queue()
	Gvint.Utils.write_file(save_path, get_content())
	if not file_path:
		file_path = save_path
		filename = save_path.split("/")[-1]
	if save_path == file_path:
		modified_time = int(Time.get_unix_time_from_system())
		has_unsaved_changes = false
	if Engine.is_editor_hint():
		EditorInterface.get_resource_filesystem().scan()
