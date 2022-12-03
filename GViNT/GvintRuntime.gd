class_name GvintRuntime extends Node

const Context = preload("res://GViNT/GvintContext.gd")
const Translator = preload("res://GViNT/Translator/SequenceTranslator.gd")

var runtime_variables := {}
var context_stack := []
var current_context: Context

var translator := Translator.new()
var tokenizer := translator.tokenizer

func _get(property):
	if property in runtime_variables:
		return runtime_variables[property]


func _ready():
	var text = load_test_file_data()
	
	tokenizer.clear()
	var start_time = OS.get_ticks_msec()
	var result := tokenizer.tokenize_text(text)
	var run_time = OS.get_ticks_msec() - start_time
	var i = 1
	var message = ""
	for line in result.tokenized_lines:
		message = str(i) + ": "
		for token in line:
			message += (token.type) + ", "
		print(message)
		i += 1
	print("tokenized in " + str(run_time) + "ms")
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


