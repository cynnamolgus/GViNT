extends Reference

var target_tokens := []
var value_tokens := []

var target_string := ""
var value_string := ""

func apply_to_template(template: String):
	for t in target_tokens:
		target_string += t.text
	for t in value_tokens:
		value_string += t.text
	return template.format({
		"target": value_string,
		"value": value_string
	})
	
