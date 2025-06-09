@tool
extends MenuButton

signal show_line_numbers_changed(value: bool)
signal line_wrap_changed(value: bool)
signal file_list_toggled

const STATE_SAVEFILE_PATH = "res://addons/GViNT/Editor/editor_preferences.json"

const ID_SHOW_LINE_NUMBERS = 0
const ID_LINE_WRAP = 1
const ID_SHOW_FILE_LIST = 2

var plugin: EditorPlugin


func _ready() -> void:
	if (not plugin) and Engine.is_editor_hint():
		return
	var popup := get_popup()
	@warning_ignore_start("int_as_enum_without_cast", "int_as_enum_without_match")
	popup.add_check_item("Show line numbers", ID_SHOW_LINE_NUMBERS)
	popup.set_item_checked(ID_SHOW_LINE_NUMBERS, true)
	popup.add_check_item("Line wrap", ID_LINE_WRAP)
	popup.set_item_checked(ID_LINE_WRAP, false)
	popup.add_check_item("Show file list", ID_SHOW_FILE_LIST)
	popup.set_item_checked(ID_SHOW_FILE_LIST, true)
	popup.set_item_accelerator(ID_SHOW_FILE_LIST, KEY_MASK_CTRL | KEY_L)
	popup.id_pressed.connect(_on_id_pressed)
	restore_state()


func restore_state() -> void:
	var state := Gvint.Utils.read_json_dict(STATE_SAVEFILE_PATH)
	if state.is_empty():
		return
	assert("show_line_numbers" in state)
	assert("wrap_lines" in state)
	assert("show_file_list" in state)
	var popup := get_popup()
	popup.set_item_checked(ID_SHOW_LINE_NUMBERS, state.show_line_numbers)
	popup.set_item_checked(ID_LINE_WRAP, state.wrap_lines)
	popup.set_item_checked(ID_SHOW_FILE_LIST, state.show_file_list)


func _on_id_pressed(id: int) -> void:
	var popup := get_popup()
	match id:
		ID_SHOW_LINE_NUMBERS:
			var show_line_numbers := not popup.is_item_checked(id)
			popup.set_item_checked(id, show_line_numbers)
			show_line_numbers_changed.emit(show_line_numbers)
		ID_LINE_WRAP:
			var line_wrap := not popup.is_item_checked(id)
			popup.set_item_checked(id, line_wrap)
			line_wrap_changed.emit(line_wrap)
		ID_SHOW_FILE_LIST:
			popup.set_item_checked(id, not popup.is_item_checked(id))
			file_list_toggled.emit()


func _on_hotkey_manager_toggle_file_list_requested() -> void:
	var popup := get_popup()
	popup.set_item_checked(
			ID_SHOW_FILE_LIST, 
			not popup.is_item_checked(ID_SHOW_FILE_LIST)
	)
