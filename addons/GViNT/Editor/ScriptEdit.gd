tool
extends TextEdit

var plugin: EditorPlugin setget set_plugin

func set_plugin(new_value):
	plugin = new_value
	setup_syntax_highlighting(plugin.get_editor_interface().get_editor_settings())


func setup_syntax_highlighting(editor_settings: EditorSettings):
	var keyword_color = editor_settings.get_setting("text_editor/highlighting/keyword_color")
	add_keyword_color("true", keyword_color)
	add_keyword_color("false", keyword_color)
	add_keyword_color("if", keyword_color)
	add_keyword_color("else", keyword_color)
	add_keyword_color("elif", keyword_color)
	add_keyword_color("and", keyword_color)
	add_keyword_color("or", keyword_color)
	add_keyword_color("not", keyword_color)
	add_keyword_color("in", keyword_color)
	
	var string_color = editor_settings.get_setting("text_editor/highlighting/string_color")
	add_color_region("\"", "\"", string_color)
	add_color_region(":", "", string_color, true)
	
	add_color_region("#", "", editor_settings.get_setting("text_editor/highlighting/comment_color"), true)
	
	add_color_override("member_variable_color", editor_settings.get_setting("text_editor/highlighting/member_variable_color"))
	add_color_override("number_color", editor_settings.get_setting("text_editor/highlighting/number_color"))
	add_color_override("function_color", editor_settings.get_setting("text_editor/highlighting/function_color"))
	
	add_color_override("symbol_color", editor_settings.get_setting("text_editor/highlighting/symbol_color"))
	add_color_override("font_color", editor_settings.get_setting("text_editor/highlighting/text_color"))
	add_color_override("background_color", editor_settings.get_setting("text_editor/highlighting/background_color"))
	add_color_override("current_line_color", editor_settings.get_setting("text_editor/highlighting/current_line_color"))

