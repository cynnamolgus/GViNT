extends Reference

const Tokenizer = preload("res://GViNT/Translator/Tokenizer/Tokenizer.gd")
const Parser = preload("res://GViNT/Translator/Parser/Parser.gd")

var tokenizer := Tokenizer.new()
var parser := Parser.new()


#var callbacks := {
#	"some_gvint_method": {
#		"target_object": "runtime",
#		"method": "some_gdscript_method"
#	}
#}


func translate_parse_result(action_instructions) -> Array:
	var actions = []
	return actions


