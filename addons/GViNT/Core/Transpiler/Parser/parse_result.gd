extends RefCounted


var instructions: Array[Gvint.ParseInstruction]
var errors: Array[Gvint.TranspileError]


func get_instruction_on_line(line_index: int) -> Gvint.ParseInstruction:
	var result = null
	for instruction in instructions:
		if (
				line_index >= instruction.start_line
				and line_index <= instruction.end_line
		):
			result = instruction
			break
	return result


func debug_print_instructions():
	var message = "INSTRUCTIONS:\n"
	for instruction in instructions:
		if instruction is Gvint.ParseInstructionDisplayText:
			var first_text_expr = instruction.text_expressions[0]
			if first_text_expr.components[0] is Gvint.Token:
				message += str(first_text_expr.components[0]) + "\n"
			else:
				message += "Display text\n"
		elif instruction is Gvint.ParseInstructionSetVariable:
			message += "Set variable\n"
		elif instruction is Gvint.ParseInstructionCall:
			message += "Call\n"
		elif instruction is Gvint.ParseInstructionIfCondition:
			message += "If condition\n"
	print(message)
