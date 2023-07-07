tool
extends PanelContainer

const GvintUtils = preload("res://addons/GViNT/Core/Utils.gd")
const ScriptEditData = preload("res://addons/GViNT/Editor/ScriptEditData.gd")


onready var open_file_dialog: FileDialog = find_node("OpenFileDialog")
onready var new_file_dialog: FileDialog = find_node("NewFileDialog")
onready var rename_file_dialog: FileDialog = find_node("RenameFileDialog")
onready var close_confirm_dialog: ConfirmationDialog = find_node("ConfirmationDialog")

onready var script_text_edit: TextEdit = find_node("TextEdit")
onready var file_list: ItemList = find_node("FileList")
onready var file_context_menu: PopupMenu = find_node("FileContextMenu")

var plugin: EditorPlugin setget set_plugin

var current_script: ScriptEditData

var opened_files := {}

var ctrl_pressed: bool = false


func set_plugin(new_value):
	plugin = new_value
	script_text_edit.plugin = plugin


func _input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_S:
			if ctrl_pressed:
				save_all_files()
			
		if event.scancode == KEY_CONTROL:
			ctrl_pressed = event.pressed
	pass


func file_exists(path: String):
	var f:= File.new()
	return f.file_exists(path)


func activate_script_editing(path: String, file_name: String):
	if not file_exists(path):
		GvintUtils.save_file(path, "")
	if not path in opened_files:
		open_file(path, file_name)
	
	if current_script:
		current_script.editing_active = false
	
	current_script = opened_files[path]
	current_script.editing_active = true
	file_list.select(current_script.position_in_file_list)
	script_text_edit.readonly = false


func open_file(path, file_name):
	var script_data := ScriptEditData.new()
	
	script_data.connect("modified", self, "on_script_modified")
	script_data.connect("saved", self, "on_script_saved")
	script_data.connect("closed", self, "on_script_closed")
	
	script_data.load_file(path)
	
	script_data.close_confirm_dialog = close_confirm_dialog
	script_data.file_name = file_name
	
	opened_files[path] = script_data
	script_data.script_text_edit = script_text_edit
	script_data.file_list = file_list


func save_all_files():
	for script_path in opened_files:
		var script_data: ScriptEditData = opened_files[script_path]
		script_data.save_file()


func select_script_for_editing(script_data: ScriptEditData):
	current_script.editing_active = false
	
	current_script = script_data
	current_script.editing_active = true
	script_text_edit.readonly = false
	script_text_edit.text = script_data.text
	script_text_edit.clear_undo_history()


func on_script_modified(script_data: ScriptEditData):
	var i = script_data.position_in_file_list
	file_list.set_item_text(i, script_data.file_path + "(*)")


func on_script_saved(script_data: ScriptEditData):
	var i = script_data.position_in_file_list
	file_list.set_item_text(i, script_data.file_path)


func on_script_closed(script_data: ScriptEditData):
	opened_files.erase(script_data.file_path)
	if script_data == current_script:
		script_text_edit.text = ""
		script_text_edit.readonly = true
	var position = script_data.position_in_file_list
	for path in opened_files:
		var data: ScriptEditData = opened_files[path]
		if data.position_in_file_list > position:
			data.position_in_file_list -= 1




func _on_OpenFileDialog_file_selected(path):
	var file_name = open_file_dialog.current_file
	activate_script_editing(path, file_name)

func _on_NewFileDialog_file_selected(path):
	var file_name = new_file_dialog.current_file
	activate_script_editing(path, file_name)
	new_file_dialog.invalidate()
	open_file_dialog.invalidate()
	rename_file_dialog.invalidate()


func _on_NewFileButton_pressed():
	new_file_dialog.popup_centered_clamped()

func _on_OpenFileButton_pressed():
	open_file_dialog.popup_centered_clamped()

func _on_TextEdit_text_changed():
	current_script.text = script_text_edit.text


func _on_FileList_item_selected(index):
	var script_data: ScriptEditData = file_list.get_item_metadata(index)
	select_script_for_editing(script_data)

func _on_FileList_item_activated(index):
	var script_data: ScriptEditData = file_list.get_item_metadata(index)
	select_script_for_editing(script_data)

func _on_FileList_item_rmb_selected(index, at_position):
	var script_data: ScriptEditData = file_list.get_item_metadata(index)
	file_context_menu.target_script = script_data
	file_context_menu.rect_global_position = file_list.rect_global_position + at_position
	file_context_menu.popup()


func _on_FileContextMenu_file_deleted(path: String):
	var script_data: ScriptEditData = opened_files[path]
	script_data.confirm_close()
	opened_files.erase(path)



func serialize_state():
	pass

func restore_state():
	pass


