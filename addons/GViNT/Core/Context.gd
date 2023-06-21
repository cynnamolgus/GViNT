class_name GvintContext extends Reference

var source_filename: String
var statements: Array
var current_statement: int = 0


func is_finished():
	return current_statement >= statements.size()


func next_statement():
	current_statement += 1
	return statements[current_statement - 1]


func previous_statement():
	current_statement -= 1
	return statements[current_statement]
