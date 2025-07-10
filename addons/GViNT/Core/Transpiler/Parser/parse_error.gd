extends Gvint.TranspileError


func _to_string() -> String:
	return "Parser error at (%s, %s): %s" % [line + 1, column + 1, text]
