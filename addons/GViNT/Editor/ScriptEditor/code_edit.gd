@tool
extends CodeEdit



const Tokenizer = Gvint.Tokenizer
const DEFAULT_HIGHLIGHTER_SETTINGS: Dictionary = {
	"Gvint/editor_highlighting/number_color": Color("eb9433"),
	"Gvint/editor_highlighting/symbol_color": Color("badeff"),
	"Gvint/editor_highlighting/function_color": Color("66a3cf"),
	"Gvint/editor_highlighting/member_variable_color": Color("e64f59"),
	"Gvint/editor_highlighting/keyword_color": Color("ffffb3"),
	"Gvint/editor_highlighting/gdscript_function_color": Color("a3a3f5"),
	"Gvint/editor_highlighting/base_type_color": Color("a3ffd4"),
	"Gvint/editor_highlighting/comment_color": Color("666666"),
	"Gvint/editor_highlighting/string_color": Color("f06ebf"),
	"Gvint/editor_highlighting/blocked_keyword_color": Color.RED,
	"Gvint/editor_highlighting/mark_color": Color("ff666666"),
}

var file: Gvint.EditorFile
var parse_delay_timer: Timer
var line_count_before_last_edit := 1
var current_error: Gvint.TranspileError:
	set = set_current_error
@onready var mark_color = ProjectSettings.get("Gvint/editor_highlighting/mark_color")

func _ready() -> void:
	highlight_current_line = true
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	text = file.get_content()
	setup_syntax_highlighter()
	line_count_before_last_edit = get_line_count()
	_init_parse_delay_timer()
	clear_undo_history()
	lines_edited_from.connect(_on_lines_edited)


func setup_syntax_highlighter():
	syntax_highlighter = CodeHighlighter.new()
	
	syntax_highlighter.number_color = ProjectSettings.get_setting("Gvint/editor_highlighting/number_color")
	syntax_highlighter.symbol_color = ProjectSettings.get_setting("Gvint/editor_highlighting/symbol_color")
	syntax_highlighter.function_color = ProjectSettings.get_setting("Gvint/editor_highlighting/function_color")
	syntax_highlighter.member_variable_color = ProjectSettings.get_setting("Gvint/editor_highlighting/member_variable_color")
	
	var keyword_color: Color = ProjectSettings.get_setting("Gvint/editor_highlighting/keyword_color")
	var gdscript_function_color: Color = ProjectSettings.get_setting("Gvint/editor_highlighting/gdscript_function_color")
	var base_type_color: Color = ProjectSettings.get_setting("Gvint/editor_highlighting/base_type_color")
	var comment_color: Color = ProjectSettings.get_setting("Gvint/editor_highlighting/comment_color")
	var string_color: Color = ProjectSettings.get_setting("Gvint/editor_highlighting/string_color")
	var blocked_keyword_color: Color = ProjectSettings.get_setting("Gvint/editor_highlighting/blocked_keyword_color")
	
	for keyword in (
			Tokenizer.KEYWORDS 
			+ Tokenizer.KEYWORD_LITERALS
			+ Gvint.GDScriptBuiltins.BUILTIN_CONSTANTS
	):
		syntax_highlighter.add_keyword_color(
			keyword,
			keyword_color
		)
	
	for function in Gvint.GDScriptBuiltins.BUILTIN_FUNCTIONS:
		syntax_highlighter.add_keyword_color(
			function,
			gdscript_function_color
		)
	
	for type in Gvint.GDScriptBuiltins.BUILTIN_TYPES:
		syntax_highlighter.add_keyword_color(
			type,
			base_type_color
		)
	
	for keyword in Gvint.GDScriptBuiltins.RESERVED_KEYWORDS:
		syntax_highlighter.add_keyword_color(
			keyword,
			blocked_keyword_color
		)
	
	syntax_highlighter.add_color_region(
		Tokenizer.COMMENT_MARK, "", comment_color
	)
	syntax_highlighter.add_color_region(
		Tokenizer.SINGLE_QUOTE, Tokenizer.SINGLE_QUOTE, string_color
	)
	syntax_highlighter.add_color_region(
		Tokenizer.QUOTE, Tokenizer.QUOTE, string_color
	)
	


func set_current_error(error: Gvint.TranspileError):
	if current_error and current_error.line < get_line_count():
		set_line_background_color(current_error.line, Color.TRANSPARENT)
	current_error = error
	if current_error:
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
