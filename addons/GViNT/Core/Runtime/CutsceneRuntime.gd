tool
class_name CutsceneRuntime extends GvintRuntime

func _init():
	if Engine.editor_hint:
		config_id = "cutscene"

func init_runtime_var(identifier: String, default_value = null):
	if not identifier in runtime_variables:
		runtime_variables[identifier] = default_value
	return runtime_variables[identifier]

func _set_runtime_var_value(identifier: String, value):
	runtime_variables[identifier] = value

func display_text(text: String, params: Array):
	print(str(params) + ": " + text)
	yield(get_tree().create_timer(1.0), "timeout")

