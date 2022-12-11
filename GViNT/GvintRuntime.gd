class_name GvintRuntime extends Node



signal action_completed
signal undo_completed



const Context = preload("res://GViNT/GvintContext.gd")
const Translator = preload("res://GViNT/Translator/Translator.gd")


var runtime_variables := {}
var context_stack := []
var current_context: Context

var translator := Translator.new()



func _get(property):
	if property in runtime_variables:
		return runtime_variables[property]


func _ready():
	var gdscript = translator.translate_file("res://lorem.txt")
	var f = File.new()
	var i = 0
	for source in gdscript:
		i += 1
		f.open("res://temp/" + str(i) + ".gd", File.WRITE)
		f.store_string(source)
		f.close()


func init_runtime_var(identifier: String):
	if not identifier in runtime_variables:
		runtime_variables[identifier] = GvintVariable.new()
	return runtime_variables[identifier]


func next_action():
	
	pass


func undo_last_action():
	
	pass


