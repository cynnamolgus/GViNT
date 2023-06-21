extends "res://addons/GViNT/Core/Translator/Statements/ConditionalBranch.gd"


var branches = [self]
var current_branch = 0


func _to_string():
	var result = Templates.CONDITIONAL_STATEMENT
	var branch_class_definitions = ""
	var branch_class_names = []
	var sub_conditions = ""
	var branch_index = 0
	for b in branches:
		branch_class_names.append([])
		var statement_index = 0
		for s in b.branch_statements:
			s.statement_id = (statement_id 
				+ "_branch" + str(branch_index) 
				+ "_" + str(statement_index)
			)
			
			var statement_class: String = s.to_string()
			statement_class = GvintUtils.indent_text_lines(statement_class, 1)
			
			branch_class_definitions += statement_class + "\n"
			branch_class_names.back().append(Templates.STATEMENT_PREFIX + s.statement_id)
			
			statement_index += 1
		branch_index += 1
	branch_class_definitions = branch_class_definitions.trim_suffix("\n")
	
	var branch_context_getters = ""
	branch_index = 0
	for b in branch_class_names:
		
		var branch_id = "branch" + str(branch_index)
		var class_names := GvintUtils.pretty_print_array(b)
		class_names = GvintUtils.indent_text_lines(class_names, 1)
		while class_names.begins_with("	"):
			class_names = class_names.trim_prefix("	")
		
		branch_index += 1
		
		var context_getter = Templates.CONDITIONAL_CONTEXT_GETTER.format({
			"branch_id": branch_id,
			"statement_class_names": class_names
		})
		context_getter = GvintUtils.indent_text_lines(context_getter, 1)
		branch_context_getters += context_getter + "\n"
	branch_context_getters = branch_context_getters.trim_suffix("\n")
	
	
	result = result.format({
		"statement_id": statement_id,
		"nested_statements": branch_class_definitions,
		"context_getters": branch_context_getters,
		"main_condition": condition,
		"sub_conditions": sub_conditions
	})
	
	return result

