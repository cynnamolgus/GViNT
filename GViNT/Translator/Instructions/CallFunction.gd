extends Reference

var target_tokens := []
var method_tokens := []
var params_tokens := []

var target_string := ""
var method_string := ""
var params_string := ""

var undo_method: String

func apply_to_template(template: String):
	for t in target_tokens:
		target_string += t.text
	for t in method_tokens:
		method_string += t.text
	for t in params_tokens:
		params_string += t.text
	return template.format({
		"target": target_string,
		"method": method_string,
		"undo_method": undo_method,
		"params": params_string
	})
	
