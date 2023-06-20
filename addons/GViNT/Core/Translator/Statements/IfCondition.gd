extends "res://addons/GViNT/Core/Translator/Statements/Statement.gd"


var condition_tokens := []
var branch_statements = []
var branches = [self]
var current_branch = 0

var indent_amount: int = 0

func construct_from_tokens(tokens: Array):
	pass


func _to_string():
	var result = Templates.CONDITIONAL_STATEMENT
	var branch_classes = []
	var branch_index = 0
	for b in branches:
		branch_classes.append([])
		var statement_index = 0
		for s in b.branch_statements:
			s.statement_id = (statement_id 
				+ "_branch" + str(branch_index) 
				+ "_" + str(statement_index)
			)
			var statement_class: String = s.to_string()
			statement_class = GvintUtils.indent_text_lines(statement_class, indent_amount)
			branch_classes.back().append(statement_class)
			statement_index += 1
		branch_index += 1

