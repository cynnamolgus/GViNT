class_name GvintContext extends Reference

var source_filename: String
var instructions: Array
var current_instruction: int = 0


func next_instruction():
	current_instruction += 1
	return instructions[current_instruction - 1]


func previous_instruction():
	current_instruction -= 1
	return instructions[current_instruction]
