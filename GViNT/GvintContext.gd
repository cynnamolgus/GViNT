extends Reference

var source_filename: String
var action_sequence: Array
var current_action: int = -1


func next_action():
	current_action += 1
	return action_sequence[current_action - 1]


func previous_action():
	current_action -= 1
	return action_sequence[current_action]
