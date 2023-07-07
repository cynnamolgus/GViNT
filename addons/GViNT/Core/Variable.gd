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
	
	assert(
		(value is Resource 
		or not (value is Object))
		and not (value is Array or value is Dictionary), 
		"Invalid value type - GvintVariable can only store primitives and resources in order to be serializable")
	if value is Resource:
		assert(value.resource_path, "Invalid GvintVariable value: resource does not have resource_path set, which is needed for serialization")
	
	
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


func serialize_state() -> Array:
	var result = []
	for v in history:
		if v is Resource:
			result.append({
				"type": "resource",
				"value": v.resource_path
			})
		else:
			result.append({
				"type": "primitive",
				"value": v
			})
	
	if value is Resource:
		result.append({
			"type": "resource",
			"value": value.resource_path
		})
	else:
		result.append({
			"type": "primitive",
			"value": value
		})
		
	return result


func load_state(savestate_data: Array):
	history.clear()
	
	var current_value_data = savestate_data.pop_back()
	if current_value_data.type == "primitive":
		value = current_value_data.value
	else:
		value = load(current_value_data.value)
	
	for d in savestate_data:
		var v
		if d.type == "primitive":
			v = d.value
		else:
			v = load(d.value)
		history.push_back(v)
	pass
