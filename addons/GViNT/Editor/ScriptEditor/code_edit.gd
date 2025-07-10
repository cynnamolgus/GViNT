@tool
extends CodeEdit


var file: Gvint.EditorFile
var parse_delay_timer: Timer
var line_count_before_last_edit := 1
var current_error: Gvint.TranspileError:
	set = set_current_error


func _ready() -> void:
	highlight_current_line = true
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	text = file.get_content()
	line_count_before_last_edit = get_line_count()
	_init_parse_delay_timer()
	clear_undo_history()
	lines_edited_from.connect(_on_lines_edited)


func set_current_error(error: Gvint.TranspileError):
	if current_error and current_error.line < get_line_count():
		set_line_background_color(current_error.line, Color.TRANSPARENT)
	current_error = error
	if current_error:
		var mark_color = Color(1.0, 0, 0, 0.5)
		if Engine.is_editor_hint():
			mark_color = EditorInterface.get_editor_settings().get_setting("text_editor/theme/highlighting/mark_color")
		set_line_background_color(current_error.line, mark_color)


func _init_parse_delay_timer() -> void:
	parse_delay_timer = Timer.new()
	parse_delay_timer.wait_time = 1.0
	parse_delay_timer.one_shot = true
	parse_delay_timer.timeout.connect(_on_parse_delay_timeout)
	add_child(parse_delay_timer)


func _on_lines_edited(from_line: int, to_line: int) -> void:
	var new_line_count := get_line_count()
	if from_line == to_line:
		file.queue_set_line(from_line, get_line(from_line))
		
		var removed_lines = new_line_count - line_count_before_last_edit
		if removed_lines > 0:
			file.queue_remove_lines(from_line, removed_lines)
	elif from_line < to_line:
		file.queue_set_line(from_line, get_line(from_line))
		var lines_inserted_at := from_line + 1
		var new_lines := []
		for i in range(lines_inserted_at, to_line + 1):
			new_lines.append(get_line(i))
		file.queue_insert_lines(lines_inserted_at, new_lines)
	elif from_line > to_line:
		file.queue_set_line(to_line, get_line(to_line))
		file.queue_remove_lines(to_line, from_line - to_line)
	line_count_before_last_edit = new_line_count
	parse_delay_timer.start()


func _on_parse_delay_timeout() -> void:
	file.flush_changes_queue()
