@tool
extends CodeEdit

signal line_modified(line: int, line_text: String)
signal lines_inserted(at_index: int, lines: Array)
signal lines_removed(after_index: int, line_count: int)

var line_count_before_last_edit := 1



func load_file_data(file: EditorGvintFileData):
	clear_undo_history()
	if file:
		lines_edited_from.disconnect(_on_lines_edited)
		text = file.get_content()
		lines_edited_from.connect(_on_lines_edited)
		editable = true
	else:
		_on_file_cleared()


func _on_text_set() -> void:
	line_count_before_last_edit = get_line_count()

func _on_lines_edited(from_line: int, to_line: int) -> void:
	#print("edited %s - %s" % [from_line, to_line])
	var new_line_count := get_line_count()
	if from_line == to_line:
		line_modified.emit( from_line, get_line(from_line) )
		
		var removed_lines = new_line_count - line_count_before_last_edit
		if removed_lines > 0:
			lines_removed.emit( from_line, removed_lines )
	elif from_line < to_line:
		line_modified.emit( from_line, get_line(from_line) )
		var lines_inserted_at := from_line + 1
		var new_lines := []
		for i in range(lines_inserted_at, to_line + 1):
			new_lines.append(get_line(i))
		lines_inserted.emit(lines_inserted_at, new_lines)
	elif from_line > to_line:
		line_modified.emit( to_line, get_line(to_line) )
		lines_removed.emit( to_line, from_line - to_line )
	line_count_before_last_edit = new_line_count
	$ParseDelayTimer.start()

func _on_file_cleared():
	editable = false
	lines_edited_from.disconnect(_on_lines_edited)
	text = "Create or open a file to edit..."
	lines_edited_from.connect(_on_lines_edited)
