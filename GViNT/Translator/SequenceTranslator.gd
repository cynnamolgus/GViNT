extends Reference

const Tokenizer = preload("res://GViNT/Translator/Tokenizer/Tokenizer.gd")

var tokenizer := Tokenizer.new()

#onready var runtime = get_parent()

#var callbacks := {
#	"some_gvint_method": {
#		"target_object": runtime,
#		"method": "some_gdscript_method"
#	}
#}


#translate parse result into array of action objects
func translate_parse_result(action_instructions) -> Array:
	var actions = []
	return actions


