class_name GvintVariable extends Reference

signal variable_value_changed

var variable_value setget set_variable_value
var history := []


func set_variable_value(new_value):
	history.push_back(variable_value)
	if "variable_value" in new_value:
		variable_value = new_value.variable_value
	else:
		variable_value = new_value
	emit_signal("variable_value_changed", variable_value)


func undo_last_change():
	assert(not history.empty())
	if not history.empty():
		variable_value = history.pop_back()
	emit_signal("variable_value_changed", variable_value)


func _to_string() -> String:
	return str(variable_value) + "#("  + str(len(history)) + ")"
