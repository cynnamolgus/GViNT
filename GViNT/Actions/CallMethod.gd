extends "res://GViNT/Actions/BaseAction.gd"

var target: Object
var method: String
var undo_method: String
var params: Array


func execute():
	target.callv(method, params)
	emit_signal("action_completed")


func undo():
	target.call(undo_method)
	emit_signal("undo_completed")
