tool
class_name VNRuntime extends "res://addons/GViNT/Core/Runtime/GvintRuntime.gd"


const FINISHED = "FINISHED"


var text_box_nodepath = "../PanelContainer/MarginContainer/RichTextLabel"
var name_label_nodepath = "../PanelContainer/NameLabelContainer/NameLabel"

class DisplayedTextData:
	var text: String
	var params: Array


var yielding_statements := []

var last_yielded_funcstate: GDScriptFunctionState

var execution_flow = null


func _init():
	if Engine.editor_hint and not config_id:
		config_id = "cutscene"
	init_runtime_var("number", 42)

func _ready():
	$LineEdit.number_variable = runtime_variables["number"]



func start(script_filename: String):
	var context_factory = GvintScripts.load_script(script_filename, config_id)
	_enter_context(context_factory.create_context())
	execute_until_yield()


func execute_next_statement():
	if current_context.is_finished():
		_exit_context()
		if not current_context:
			return FINISHED
	
	var script_statement = current_context.next_statement()
	var result
	if script_statement.new().has_method("evaluate_conditional"):
		var conditional_context = script_statement.evaluate_conditional(self)
		_enter_context(conditional_context)
	else:
		result = script_statement.evaluate(self)
		if result is GDScriptFunctionState:
			if not yielding_statements.has(script_statement):
				yielding_statements.append(script_statement)
			last_yielded_funcstate = result
			last_yielded_funcstate.connect("completed", self, "on_last_yielded_statement_completed")
			return result
	return null

func execute_until_yield():
	var result
	while true:
		if result is String:
			if result == FINISHED:
				break
		result = execute_next_statement()
		if result is GDScriptFunctionState:
			break

func undo_until_yield():
	var reached_yielding_statement = false
	while current_context and not reached_yielding_statement:
		if current_context.current_statement == 0:
			_exit_context()
			if not current_context:
				break
		var previous_statement = current_context.previous_statement()
		if previous_statement.has_method("evaluate_conditional"):
			continue
		if previous_statement in yielding_statements:
			reached_yielding_statement = true
			previous_statement = current_context.previous_statement()
			if previous_statement.new().has_method("undo"):
				previous_statement.undo(self)
		else:
			if previous_statement.new().has_method("undo"):
				previous_statement.undo(self)


func on_last_yielded_statement_completed():
	last_yielded_funcstate.disconnect("completed", self, "on_last_yielded_statement_completed")
	last_yielded_funcstate = null
	if current_context:
		execute_until_yield()

func step_backwards():
	if not current_context:
		return
	if last_yielded_funcstate:
		last_yielded_funcstate.disconnect("completed", self, "on_last_yielded_statement_completed")
		last_yielded_funcstate = null
	undo_until_yield()
	execute_until_yield()


func init_runtime_var(identifier: String, default_value = null):
	if not identifier in runtime_variables:
		var runtime_var := GvintVariable.new()
		if default_value:
			runtime_var.value = default_value
		runtime_variables[identifier] = runtime_var
	return runtime_variables[identifier]


func _set_runtime_var_value(identifier: String, value):
	var runtime_var = runtime_variables[identifier]
	assert(runtime_var is GvintVariable)
	runtime_var.value = value


func display_text(text: String, params: Array):
	print(str(params) + ": " + text)
	get_node(name_label_nodepath).text = str(params[0]) if params else ""
	get_node(text_box_nodepath).display_text(text)
	yield(get_node(text_box_nodepath), "advance_text")

