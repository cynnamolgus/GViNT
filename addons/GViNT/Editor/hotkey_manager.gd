@tool
extends Control

signal save_requested
signal save_as_requested
signal close_file_requested
signal new_file_requested
signal open_file_requested
signal move_up_requested
signal move_down_requested
signal toggle_file_list_requested
signal search_requested
signal search_and_replace_requested

var plugin: EditorPlugin
var ctrl_pressed: bool = false
var shift_pressed: bool = false

var file_is_open: bool = false


func _input(event: InputEvent) -> void:
	if (not plugin) and Engine.is_editor_hint():
		return
	if not is_visible_in_tree():
		return
	
	if event is InputEventKey:
		if event.pressed and event.ctrl_pressed and event.shift_pressed:
			_handle_ctrl_shift_keypress_event(event)
		elif event.pressed and event.ctrl_pressed:
			_handle_ctrl_keypress_event(event)


func _handle_ctrl_shift_keypress_event(event: InputEventKey):
	match event.keycode:
		KEY_S:
			if file_is_open:
				save_as_requested.emit()
			get_viewport().set_input_as_handled()
		KEY_UP:
			if file_is_open:
				move_up_requested.emit()
			get_viewport().set_input_as_handled()
		KEY_DOWN:
			if file_is_open:
				move_down_requested.emit()
			get_viewport().set_input_as_handled()


func _handle_ctrl_keypress_event(event: InputEventKey):
	match event.keycode:
		KEY_S:
			if file_is_open:
				save_requested.emit()
			get_viewport().set_input_as_handled()
		KEY_W:
			if file_is_open:
				close_file_requested.emit()
			get_viewport().set_input_as_handled()
		KEY_N:
			new_file_requested.emit()
			get_viewport().set_input_as_handled()
		KEY_O:
			open_file_requested.emit()
			get_viewport().set_input_as_handled()
		KEY_L:
			toggle_file_list_requested.emit()
			get_viewport().set_input_as_handled()
		KEY_F:
			search_requested.emit()
			get_viewport().set_input_as_handled()
		KEY_R:
			search_and_replace_requested.emit()
			get_viewport().set_input_as_handled()


func _on_file_manager_file_opened(_file: Gvint.EditorFile) -> void:
	file_is_open = true


func _on_file_manager_all_files_closed() -> void:
	file_is_open = false
