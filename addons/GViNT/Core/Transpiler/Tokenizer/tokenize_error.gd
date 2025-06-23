extends RefCounted

var text: String
var line: int
var column: int

func _to_string() -> String:
	return "Tokenizer error at (%s, %s): %s" % [line + 1, column + 1, text]
