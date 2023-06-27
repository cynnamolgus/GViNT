tool
class_name VNRuntime extends "res://addons/GViNT/Core/Runtime/GvintRuntime.gd"


const FINISHED = "FINISHED"


var text_box_nodepath = "../PanelContainer/MarginContainer/RichTextLabel"
var name_label_nodepath = "../PanelContainer/NameLabelContainer/NameLabel"

class DisplayedTextData:
	var text: String
	var params: Array


var context_spawning_statements := []
var yielding_statements := []

var last_yielded_funcstate: GDScriptFunctionState



func _init():
	if Engine.editor_hint:
		if not config_id:
			config_id = "cutscene"
	init_runtime_var("number", 1337)

func _ready():
	$LineEdit.number_variable = runtime_variables["number"]



func start(script_filename: String):
	var is_running = current_context != null
	var invoking_statement
	if is_running:
		invoking_statement = current_context.current_statement()
	
	script_filename = _expand_source_filename(script_filename)
	var context_factory = GvintScripts.load_script(script_filename, config_id)
	_enter_context(context_factory.create_context())
	if not is_running:
		execute_until_yield()
	else:
		if not invoking_statement in context_spawning_statements:
			context_spawning_statements.push_back(invoking_statement)


func execute_next_statement():
	while current_context.is_finished():
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


func step_backwards():
	if not current_context:
		return
	if current_context.current_statement_index == 0 and not context_stack:
		return
	var undo_successful = undo_until_yield()
	if undo_successful:
		assert(last_yielded_funcstate != null)
		last_yielded_funcstate.disconnect("completed", self, "on_last_yielded_statement_completed")
		last_yielded_funcstate = null
		execute_until_yield()


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
	
	if yielding_statements.size() < 2:
		return false
	if current_context.last_executed_statement == yielding_statements.front():
		return false
	
	var previous_statement = current_context.current_statement()
	var entered_new_context = undo_statement(previous_statement)
	if entered_new_context:
		previous_statement = current_context.current_statement()
	else:
		if current_context.current_statement_index == 0:
			_exit_context()
			current_context.current_statement_index -= 1
			previous_statement = current_context.current_statement()
		else:
			previous_statement = current_context.previous_statement()
	
	while true:
		entered_new_context = undo_statement(previous_statement)
		
		if entered_new_context:
			previous_statement = current_context.current_statement()
		
		if previous_statement in yielding_statements:
			current_context.current_statement_index -= 1
			return true
		
		if current_context.current_statement_index == 0:
			_exit_context()
			if current_context.previous_statement() in yielding_statements:
				current_context.current_statement_index -= 1
				return true
		else:
			previous_statement = current_context.previous_statement()
		
	
	pass


func on_last_yielded_statement_completed():
	last_yielded_funcstate.disconnect("completed", self, "on_last_yielded_statement_completed")
	last_yielded_funcstate = null
	if current_context:
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


func _enter_context(ctx: GvintContext):
	if current_context:
		var current_statement = current_context.current_statement()
		if not current_statement in context_spawning_statements:
			context_spawning_statements.push_back(current_statement)
	._enter_context(ctx)

func _exit_context():
	._exit_context()


func undo_statement(statement):
	var entered_new_context = false
	if statement.new().has_method("undo"):
		statement.undo(self)
	if context_spawning_statements:
		if statement in context_spawning_statements:
			entered_new_context = true
			if statement.new().has_method("evaluate_conditional"):
				_enter_context(statement.evaluate_conditional(self))
			else:
				statement.evaluate(self)
			current_context.current_statement_index = current_context.statements.size() - 1
			assert(current_context.current_statement_index >= -1)
	return entered_new_context

