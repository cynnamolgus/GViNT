class_name GvintVariable extends Reference

signal variable_value_changed

var value setget set_variable_value
var history := []


func set_variable_value(new_value):
	history.push_back(value)
	value = new_value
	
	if new_value is Object:
		if "value" in new_value:
			value = new_value.value
	
	emit_signal("variable_value_changed", value)


func stateless_set(new_value):
	value = new_value


func undo_last_change():
	assert(not history.empty())
	if not history.empty():
		value = history.pop_back()
	emit_signal("variable_value_changed", value)


func _to_string() -> String:
	return str(value) + "#("  + str(len(history)) + ")"


