@tool
extends VBoxContainer


const STATE_SAVEFILE_PATH = "res://addons/GViNT/Editor/editor_preferences.json"

var current_file: Gvint.EditorFile
var show_line_numbers: bool = true:
	set = set_show_line_numbers
var wrap_lines: bool = false:
	set = set_wrap_lines

@onready var status_bar: Gvint.EditorStatusBar = $StatusBar
@onready var current_code_edit: CodeEdit = $NoFileCodeEdit:
	set = set_current_code_edit
@onready var search_menu: Gvint.EditorSearchMenu = $SearchMenu
@onready var file_list := $"../FileList"


func _ready():
	file_list.visibility_changed.connect(_on_file_list_visibility_changed)
	restore_state()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventKey:
		if (
				event.keycode == KEY_ESCAPE 
				and event.pressed
				and search_menu.is_visible_in_tree()
		):
			search_menu.hide()


func set_show_line_numbers(value: bool) -> void:
	show_line_numbers = value
	for child in get_children():
		var code_edit := child as CodeEdit
		if code_edit:
			code_edit.gutters_draw_line_numbers = show_line_numbers
	serialize_state()


func set_wrap_lines(value: bool) -> void:
	wrap_lines = value
	for child in get_children():
		var code_edit := child as CodeEdit
		if code_edit:
			code_edit.wrap_mode = (
					TextEdit.LINE_WRAPPING_BOUNDARY if wrap_lines
					else TextEdit.LINE_WRAPPING_NONE
			)
	serialize_state()


func set_current_code_edit(code_edit: CodeEdit):
	current_code_edit = code_edit
	if current_code_edit == $NoFileCodeEdit:
		$SearchMenu.current_code_edit = null
		return
	else:
		$SearchMenu.current_code_edit = current_code_edit


func serialize_state() -> void:
	var state := {
		"show_line_numbers": show_line_numbers,
		"wrap_lines": wrap_lines,
		"show_file_list": file_list.visible,
	}
	Gvint.Utils.write_json(STATE_SAVEFILE_PATH, state)


func restore_state() -> void:
	var state := Gvint.Utils.read_json_dict(STATE_SAVEFILE_PATH)
	if state.is_empty():
		return
	assert("show_line_numbers" in state)
	assert("wrap_lines" in state)
	assert("show_file_list" in state)
	show_line_numbers = state.show_line_numbers
	wrap_lines = state.wrap_lines
	if not state.show_file_list:
		file_list.hide()


func _on_file_list_visibility_changed() -> void:
	serialize_state()


func _on_file_manager_current_file_changed(file: Gvint.EditorFile) -> void:
	if not is_node_ready():
		await ready
	current_code_edit.hide()
	if file:
		current_file = file
		current_code_edit = current_file.code_edit
		status_bar.file_path = current_file.file_path if current_file.file_path else current_file.filename
		status_bar.caret_line = current_code_edit.get_caret_line()
		status_bar.caret_position = current_code_edit.get_caret_column()
	else:
		current_file = null
		current_code_edit = $NoFileCodeEdit
		status_bar.file_path = "<No file open>"
		status_bar.caret_line = -1
		status_bar.caret_position = -1
	current_code_edit.show()


func _on_file_manager_file_opened(file: Gvint.EditorFile) -> void:
	_setup_code_edit(file.code_edit)
	file.filename_changed.connect(_on_file_filename_changed)


func _setup_code_edit(code_edit: Gvint.EditorCodeEdit) -> void:
	code_edit.gutters_draw_line_numbers = show_line_numbers
	code_edit.wrap_mode = (
			TextEdit.LINE_WRAPPING_BOUNDARY if wrap_lines
			else TextEdit.LINE_WRAPPING_NONE
	)
	add_child(code_edit)
	move_child(code_edit, 0)
	code_edit.caret_changed.connect(_on_code_edit_caret_changed)


func _on_file_filename_changed() -> void:
	status_bar.file_path = current_file.file_path if current_file.file_path else current_file.filename


func _on_code_edit_caret_changed() -> void:
	status_bar.caret_line = current_code_edit.get_caret_line()
	status_bar.caret_position = current_code_edit.get_caret_column()
