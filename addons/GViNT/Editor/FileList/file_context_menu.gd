@tool
extends PopupMenu

signal save_requested
signal save_as_requested
signal close_file_requested
signal move_up_requested
signal move_down_requested

const ID_SAVE = 0
const ID_SAVE_AS = 1 
const ID_CLOSE = 2
const ID_MOVE_UP = 3
const ID_MOVE_DOWN = 4

const ID_SEPARATOR = 100

var plugin: EditorPlugin


func _ready():
	size.y = 0
	size.x = 0
	if (not plugin) and Engine.is_editor_hint():
		return
	add_item("Save", ID_SAVE, KEY_MASK_CTRL | KEY_S)
	add_item("Save as", ID_SAVE_AS, KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_S)
	add_item("Close", ID_CLOSE, KEY_MASK_CTRL | KEY_W)
	add_separator("", ID_SEPARATOR)
	add_item("Move up", ID_MOVE_UP, KEY_MASK_SHIFT | KEY_MASK_ALT | KEY_UP)
	add_item("Move down", ID_MOVE_DOWN, KEY_MASK_SHIFT | KEY_MASK_ALT | KEY_DOWN)


func _on_id_pressed(id: int) -> void:
	match id:
		ID_SAVE:
			save_requested.emit()
		ID_SAVE_AS:
			save_as_requested.emit()
		ID_CLOSE:
			close_file_requested.emit()
		ID_MOVE_UP:
			move_up_requested.emit()
		ID_MOVE_DOWN:
			move_down_requested.emit()
