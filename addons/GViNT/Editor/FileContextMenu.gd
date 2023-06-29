tool
extends PopupMenu

signal file_deleted
signal script_path_changed

const ID_SAVE = 0
const ID_RENAME = 1
const ID_MOVE_UP = 3
const ID_MOVE_DOWN = 4
const ID_CLOSE = 6

const GvintUtils = preload("res://addons/GViNT/Core/Utils.gd")
const ScriptEditData = preload("res://addons/GViNT/Editor/ScriptEditData.gd")

onready var file_list: ItemList = get_parent().find_node("FileList")
onready var open_file_dialog: FileDialog = get_parent().find_node("OpenFileDialog")
onready var new_file_dialog: FileDialog = get_parent().find_node("NewFileDialog")
onready var rename_file_dialog: FileDialog = get_parent().find_node("RenameFileDialog")

var target_script: ScriptEditData




func _on_FileContextMenu_id_pressed(id):
	match id:
		ID_SAVE:
			target_script.save_file()
		ID_RENAME:
			rename_file_dialog.popup_centered_clamped() #TODO
			pass
		ID_MOVE_UP:
			move_script_up()
		ID_MOVE_DOWN:
			move_script_down()
		ID_CLOSE:
			target_script.close()

func move_script_up():
	var target_position = target_script.position_in_file_list - 1
	move_script(target_position)

func move_script_down():
	var target_position = target_script.position_in_file_list + 1
	move_script(target_position)

func move_script(target_position):
	var source_position = target_script.position_in_file_list
	target_position = clamp(target_position, 0, file_list.get_item_count() - 1)
	if target_position == source_position:
		return
	
	var other_script: ScriptEditData = file_list.get_item_metadata(target_position)
	file_list.move_item(source_position, target_position)
	file_list.set_item_metadata(source_position, other_script)
	file_list.set_item_metadata(target_position, target_script)
	
	target_script.position_in_file_list = target_position
	other_script.position_in_file_list = source_position


func _on_RenameFileDialog_file_selected(path):
	var p = get_parent()
	
	var overwrite = path in p.opened_files
	if overwrite:
		p.opened_files[path].confirm_close()
	
	var old_path = target_script.file_path
	GvintUtils.delete_file_or_directory(old_path)
	target_script.file_path = path
	target_script.file_name = rename_file_dialog.current_file
	target_script.save_file()
	new_file_dialog.invalidate()
	open_file_dialog.invalidate()
	rename_file_dialog.invalidate()
	
	p.opened_files.erase(old_path)
	p.opened_files[path] = target_script

