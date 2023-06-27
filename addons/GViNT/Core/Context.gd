class_name GvintContext extends Reference

enum Directions {
	FORWARDS,
	BACKWARDS
}

var source_filename: String
var statements: Array
var current_statement_index: int = -1

var last_statement_id: String

var last_executed_statement

func is_finished():
	return current_statement_index >= statements.size() - 1


func next_statement():
	current_statement_index += 1
	assert(current_statement_index >= 0)
	var statement = statements[current_statement_index]
	last_statement_id = statement.get_id()
	last_executed_statement = statement
	return statement

func current_statement():
	return statements[current_statement_index]

func previous_statement():
	current_statement_index -= 1
	assert(current_statement_index >= 0)
	var statement = statements[current_statement_index]
	return statement
