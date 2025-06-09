@tool
extends MenuButton


signal search_requested
signal search_and_replace_requested


const ID_SEARCH = 0
const ID_REPLACE = 1

var plugin: EditorPlugin


func _ready() -> void:
	if (not plugin) and Engine.is_editor_hint():
		return
	var popup := get_popup()
	@warning_ignore_start("int_as_enum_without_cast", "int_as_enum_without_match")
	popup.add_item("Search", ID_SEARCH, KEY_MASK_CTRL | KEY_F)
	popup.add_item("Replace", ID_REPLACE, KEY_MASK_CTRL | KEY_R)
	popup.id_pressed.connect(_on_id_pressed)


func _on_id_pressed(id: int) -> void:
	match id:
		ID_SEARCH:
			search_requested.emit()
		ID_REPLACE:
			search_and_replace_requested.emit()
