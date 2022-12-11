extends Reference

var params_tokens := []
var params_string := ""

var text := ""
var target := ""
var method := ""
var undo_method := ""

var has_colon := false

func apply_to_template(template: String):
	for t in params_tokens:
		params_string += t.text
	return template.format({
		"target": target,
		"method": method,
		"undo_method": undo_method,
		"params": "[" + text + ", [" + params_string + "]]"
	})
