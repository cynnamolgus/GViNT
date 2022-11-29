extends Reference

var value setget set_value
var history := []


func set_value(new_value):
	history.push_back(value)
	value = new_value

func undo_last_change():
	assert(not history.empty())
	if not history.empty():
		value = history.pop_back()
