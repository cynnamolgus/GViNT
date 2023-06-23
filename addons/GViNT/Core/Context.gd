class_name GvintContext extends Reference

var source_filename: String
var statements: Array
var current_statement: int = 0

var last_statement_id: String

func is_finished():
	return current_statement >= statements.size()


func next_statement():
	current_statement += 1
	var statement = statements[current_statement - 1]
	last_statement_id = statement.get_id()
	return statement


func previous_statement():
	current_statement -= 1
	var statement = statements[current_statement]
	last_statement_id = statement.get_id()
	return statement
