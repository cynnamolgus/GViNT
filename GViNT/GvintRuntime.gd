class_name GvintRuntime extends Node



signal action_completed
signal undo_completed



const Context = preload("res://GViNT/GvintContext.gd")
const Translator = preload("res://GViNT/Translator/Translator.gd")


var runtime_variables := {}
var context_stack := []
var current_context: Context

var translator := Translator.new()

var bar = GvintVariable.new()

func _get(property):
	var stack = get_stack()
	if len(stack) <= 1:
		return null
	var calling_method = stack[1]["function"]
	var called_by_runtime_action = (
		calling_method == "execute_gvint_action"
		or calling_method == "undo_gvint_action"
	)
	if called_by_runtime_action:
#		print(calling_method + " GET " + property)
		if property in runtime_variables:
			return runtime_variables[property]
		else:
			return init_runtime_var(property)

func _set(property, value):
	if property == "foo":
		pass
	runtime_variables[property] = value
	return true


func _ready():
	var gdscript = translator.translate_file("res://test.txt")
	var actions := []
	var action: Reference
	var script: GDScript
	for source in gdscript:
		action = Reference.new()
		script = GDScript.new()
		script.source_code = source
		script.reload()
		action.set_script(script)
		actions.append(action)
	
	for a in actions:
		a.execute_gvint_action(self)
	pass


func init_runtime_var(identifier: String):
	if not identifier in runtime_variables:
		runtime_variables[identifier] = GvintVariable.new()
	return runtime_variables[identifier]

func next_action():
	
	pass


func undo_last_action():
	
	pass




func display_text(text: String, params: Array):
	print(str(params) + ": " + text)

func undo_display_text():
	print("undo")

func get_some_value():
	return 42

func do_a_thing():
	print("foo is '" + str(runtime_variables.foo) + "'")





