tool
class_name VNRuntime extends GvintRuntime

var text_box_nodepath = "../PanelContainer/MarginContainer/RichTextLabel"
var name_label_nodepath = "../PanelContainer/NameLabelContainer/NameLabel"

class DisplayedTextData:
	var text: String
	var params: Array

var text_history := []

func _init():
	if Engine.editor_hint and not config_id:
		config_id = "cutscene"


func init_runtime_var(identifier: String, default_value = null):
	if not identifier in runtime_variables:
		var runtime_var := GvintVariable.new()
		if default_value:
			runtime_var.variable_value = default_value
		runtime_variables[identifier] = runtime_var
	return runtime_variables[identifier]


func _set_runtime_var_value(identifier: String, value):
	var runtime_var = runtime_variables[identifier]
	assert(runtime_var is GvintVariable)
	runtime_var.variable_value = value


func undo_until_yield():
	assert(is_running)
	assert(currently_yielded)
	
	pause()
	
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
			current_context.previous_statement()
			resume()
		else:
			previous_statement.undo(self)

func display_text(text: String, params: Array):
	print(str(params) + ": " + text)
	get_node(name_label_nodepath).text = str(params[0]) if params else ""
	get_node(text_box_nodepath).display_text(text)
	yield(get_node(text_box_nodepath), "advance_text")

func undo_display_text():
	
	pass
