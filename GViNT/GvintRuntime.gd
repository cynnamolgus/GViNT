class_name GvintRuntime extends Node

const Context = preload("res://GViNT/GvintContext.gd")

var runtime_variables := {}
var context_stack := []
var current_context: Context

onready var tokenizer := $SequenceTranslator/Tokenizer

func _get(property):
	if property in runtime_variables:
		return runtime_variables[property]


func _ready():
	
	var text = load_test_file_data()
	
	tokenizer.tokenize_text(text)
	var i = 1
	var message = ""
	for line in tokenizer.tokenized_lines:
		message = str(i) + ": "
		for token in line:
			message += "'" + (token.text if token.text != "\n" else "LINEBREAK") + "'" + ", "
		print(message)
		i += 1
	pass


func load_test_file_data():
	var f := File.new()
	f.open("res://test.txt", File.READ)
	var text := f.get_as_text()
	f.close()
	return text





func next_action():
	
	pass


func undo_last_action():
	
	pass


