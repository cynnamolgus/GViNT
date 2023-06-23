tool
extends PanelContainer

const GvintUtils = preload("res://addons/GViNT/Core/Utils.gd")
const ScriptEditData = preload("res://addons/GViNT/Editor/ScriptEditData.gd")
const FileSelector = preload("res://addons/GViNT/Editor/FileSelector.gd")

const FILE_SELECTOR_SCENE = preload("res://addons/GViNT/Editor/FileSelector.tscn")

onready var file_picker: FileDialog = find_node("OpenFileDialog")
onready var new_file_picker: FileDialog = find_node("NewFileDialog")
onready var close_confirm_dialog: ConfirmationDialog = find_node("ConfirmationDialog")

onready var file_selectors_container: VBoxContainer = find_node("FileSelectors")
onready var text_edit: TextEdit = find_node("TextEdit")

var current_script: ScriptEditData

var opened_files := {}

var ctrl_pressed: bool = false

func _input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_S:
			if ctrl_pressed:
				save_all_files()
			
		if event.scancode == KEY_CONTROL:
			ctrl_pressed = event.pressed
	pass

func _on_OpenFileDialog_file_selected(path):
	print("selected " + "'" + path + "'")
	var file_name = file_picker.current_file
	activate_script_editing(path, file_name)

func _on_NewFileDialog_file_selected(path):
	print("selected " + "'" + path + "'")
	var file_name = new_file_picker.current_file
	activate_script_editing(path, file_name)
	new_file_picker.invalidate()
	file_picker.invalidate()


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
	text_edit.readonly = false


func open_file(path, file_name):
	var selector: FileSelector = FILE_SELECTOR_SCENE.instance()
	selector.connect("selected", self, "on_opened_script_selected")
	
	file_selectors_container.add_child(selector)
	file_selectors_container.move_child(selector, file_selectors_container.get_child_count() - 2)
	
	
	var script_data := ScriptEditData.new()
	
	script_data.connect("closed", self, "on_script_closed")
	script_data.connect("editing_activated", self, "on_script_editing_activated")
	
	script_data.load_file(path)
	
	script_data.selector = selector
	script_data.close_confirm_dialog = close_confirm_dialog
	script_data.file_name = file_name
	
	selector.script_data = script_data
	
	opened_files[path] = script_data

func save_all_files():
	for script_path in opened_files:
		var script_data: ScriptEditData = opened_files[script_path]
		script_data.save_file()

func on_script_closed(script_data: ScriptEditData):
	opened_files.erase(script_data.file_path)
	if script_data == current_script:
		text_edit.text = ""
		text_edit.readonly = true

func on_script_editing_activated(script_data: ScriptEditData):
	text_edit.text = script_data.text
	text_edit.scroll_vertical = script_data.scroll

func on_opened_script_selected(script_data: ScriptEditData):
	current_script.editing_active = false
	current_script = script_data
	current_script.editing_active = true
	text_edit.readonly = false

func _on_NewFileButton_pressed():
	new_file_picker.popup_centered_clamped()

func _on_OpenFileButton_pressed():
	file_picker.popup_centered_clamped()

func _on_SaveFileButton_pressed():
	current_script.save_file()


func _on_TextEdit_text_changed():
	current_script.text = text_edit.text

func serialize_state():
	pass

func restore_state():
	pass




