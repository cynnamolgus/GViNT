tool
extends Reference


signal editing_activated
signal editing_deactivated
signal modified
signal saved
signal closed


const GvintUtils = preload("res://addons/GViNT/Core/Utils.gd")



var selector: Control
var close_confirm_dialog: ConfirmationDialog

var editing_active: bool = false setget set_editing_active

var file_path: String
var file_name: String
var text: String setget set_text

var modified_since_last_save: bool = false

var file_list: ItemList setget set_file_list
var position_in_file_list: int
var script_text_edit: TextEdit

func set_editing_active(new_value):
	editing_active = new_value
	if editing_active:
		script_text_edit.text = text
		script_text_edit.connect("text_changed", self, "on_script_text_edit_text_changed")
		emit_signal("editing_activated", self)
	else:
		script_text_edit.disconnect("text_changed", self, "on_script_text_edit_text_changed")
		emit_signal("editing_deactivated", self)


func set_text(new_value):
	if text != new_value:
		modified_since_last_save = true
		emit_signal("modified", self)
	text = new_value


func set_file_list(new_value):
	file_list = new_value
	position_in_file_list = file_list.get_item_count()
	file_list.add_item(file_path)
	file_list.set_item_metadata(position_in_file_list, self)
	file_list.select(position_in_file_list)



func load_file(path):
	file_path = path
	text = GvintUtils.read_file(file_path)

func save_file():
	assert(file_path)
	GvintUtils.save_file(file_path, text)
	GvintScripts.compile_script(file_path, GvintScripts.configs["stateful"])
	GvintScripts.compile_script(file_path, GvintScripts.configs["stateless"])
	modified_since_last_save = false
	emit_signal("saved", self)

func close():
	if not modified_since_last_save:
		confirm_close()
	else:
		close_confirm_dialog.get_cancel().connect("pressed", self, "on_confirm_dialog_cancel")
		close_confirm_dialog.connect("confirmed", self, "confirm_close")
		close_confirm_dialog.popup_centered_minsize()

func confirm_close():
	var i = 0
	while i < file_list.get_item_count():
		if file_list.get_item_metadata(i) == self:
			break
		i += 1
	file_list.remove_item(i)
	emit_signal("closed", self)

func on_confirm_dialog_cancel():
	close_confirm_dialog.get_cancel().disconnect("pressed", self, "on_confirm_dialog_cancel")
	close_confirm_dialog.disconnect("confirmed", self, "confirm_close")

func on_script_text_edit_text_changed():
	set_text(script_text_edit.text)
