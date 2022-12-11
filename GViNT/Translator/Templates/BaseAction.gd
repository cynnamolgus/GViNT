extends Reference

signal action_completed
signal undo_completed

var runtime

var translator_metadata := {}

var _required_methods := [
	"execute",
	"undo"
]



func _validate_methods():
	var method_names := []
	var methods := get_method_list()
	for method in methods:
		method_names.append(method["name"])
	
	var has_required_methods = true
	var has_method: bool
	var missing_method := ""
	for method in _required_methods:
		has_method = (method in method_names)
		if not has_method:
			has_required_methods = false
			missing_method = method
	
	assert(has_required_methods, "Action doesn't implement method '" + missing_method + "'")


