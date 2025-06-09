@tool
extends MenuButton


signal new_file_requested
signal open_file_requested
signal save_fie_requested
signal save_file_as_requested

const ID_NEW_FILE = 0
const ID_OPEN_FILE = 1
const ID_SAVE_FILE = 2
const ID_SAVE_FILE_AS = 3

var plugin: EditorPlugin


func _ready() -> void:
	if (not plugin) and Engine.is_editor_hint():
		return
	var popup := get_popup()
	@warning_ignore_start("int_as_enum_without_cast", "int_as_enum_without_match")
	popup.add_item("New file", ID_NEW_FILE, KEY_MASK_CTRL | KEY_N)
	popup.add_item("Open file", ID_OPEN_FILE, KEY_MASK_CTRL | KEY_O)
	popup.add_item("Save current file", ID_SAVE_FILE, KEY_MASK_CTRL | KEY_S)
	popup.add_item("Save current file as", ID_SAVE_FILE_AS, KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_S)
	popup.id_pressed.connect(_on_id_pressed)


func _on_id_pressed(id: int) -> void:
	match id:
		ID_NEW_FILE:
			new_file_requested.emit()
		ID_OPEN_FILE:
			open_file_requested.emit()
		ID_SAVE_FILE:
			save_fie_requested.emit()
		ID_SAVE_FILE_AS:
			save_file_as_requested.emit()
