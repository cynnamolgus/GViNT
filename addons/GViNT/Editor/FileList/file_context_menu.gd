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
