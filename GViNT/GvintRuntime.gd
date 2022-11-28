class_name GvintRuntime extends Node

signal text
signal text_undo

var action_queue := []

var action_history := []



#can't preload due to cyclic deps...
#*looks longingly at 4.0-beta6*
#todo: add separate system to auto-load action types?
var TextAction = load("res://GViNT/Actions/TextAction.gd")



func _ready():
	var action = TextAction.new()
	action.runtime = self
	action._validate_methods()
	action.execute()
	pass


func do_a_thing(message: String):
	emit_signal("text", message)
	pass


func next_action():
	
	pass


func undo_last_action():
	
	pass


