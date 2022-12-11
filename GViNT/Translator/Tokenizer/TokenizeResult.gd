extends Reference

var source_code: String
var source_filename: String
var used_blocked_keywords := []
var used_blocked_functions := []
var used_builtin_functions := []
var used_builtin_constants := []
var tokens := []
var tokenized_lines := []

func pretty_print():
	var line_index := 1
	var message = ""
	for line in tokenized_lines:
		message = str(line_index) + ": "
		for token in line:
			message += (token.type) + ", "
		print(message)
		line_index += 1


func pretty_print_alt():
	var line_index := 1
	var message = ""
	for line in tokenized_lines:
		for token in line:
			message = "[" + str(line_index) + "] "
			message += (token.type) + ": " + token.text
			print(message)
		line_index += 1

