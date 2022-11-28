extends "res://GViNT/Actions/BaseAction.gd"



func execute():
	runtime.do_a_thing("hello world! lorem ipsum dolor sit amet")
	emit_signal("action_completed")


func undo():
	emit_signal("undo_completed")
