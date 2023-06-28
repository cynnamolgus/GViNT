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
var scroll: float = 0.0

var modified_since_last_save: bool = false


func set_editing_active(new_value):
	editing_active = new_value
	if editing_active:
		emit_signal("editing_activated", self)
	else:
		emit_signal("editing_deactivated", self)

func set_text(new_value):
	if text != new_value:
		modified_since_last_save = true
		emit_signal("modified")
	text = new_value



func load_file(path):
	file_path = path
	text = GvintUtils.read_file(file_path)

func save_file():
	assert(file_path)
	GvintUtils.save_file(file_path, text)
	modified_since_last_save = false
	emit_signal("saved")

func close():
	if not modified_since_last_save:
		confirm_close()
	else:
		close_confirm_dialog.get_cancel().connect("pressed", self, "on_confirm_dialog_cancel")
		close_confirm_dialog.connect("confirmed", self, "confirm_close")
		close_confirm_dialog.popup_centered_minsize()

func confirm_close():
	selector.queue_free()
	emit_signal("closed", self)

func on_confirm_dialog_cancel():
	close_confirm_dialog.get_cancel().disconnect("pressed", self, "on_confirm_dialog_cancel")
	close_confirm_dialog.disconnect("confirmed", self, "confirm_close")
