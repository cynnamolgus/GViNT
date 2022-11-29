extends "res://GViNT/Actions/BaseAction.gd"

var text: String
var params: Array


func execute():
	emit_signal("action_completed")


func undo():
	emit_signal("undo_completed")
