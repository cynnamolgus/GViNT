class_name GvintVariable extends Reference

signal value_changed

var value setget set_value
var history := []


func set_value(new_value):
	history.push_back(value)
	if typeof(new_value) == typeof(self):
		value = new_value.value
	else:
		value = new_value
	emit_signal("value_changed", value)


func undo_last_change():
	assert(not history.empty())
	if not history.empty():
		value = history.pop_back()
	emit_signal("value_changed", value)


func _to_string() -> String:
	return str(value) + "#("  + str(len(history)) + ")"