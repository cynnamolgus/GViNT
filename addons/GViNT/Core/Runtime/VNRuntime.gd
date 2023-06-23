tool
class_name VNRuntime extends GvintRuntime


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
	
	pass

func display_text(text: String, params: Array):
	print(str(params) + ": " + text)
	yield(get_tree().create_timer(1.0), "timeout")

func undo_display_text():
	
	pass
