extends GvintRuntimeStateful

var text_box_nodepath = "../PanelContainer/MarginContainer/RichTextLabel"
var name_label_nodepath = "../PanelContainer/NameLabelContainer/NameLabel"

func _init_runtime_variables():
	create_runtime_variable("number", 1337)
	$LineEdit.number_variable = runtime_variables["number"]


func display_text(text: String, params: Array):
	print(str(params) + ": " + text)
	get_node(name_label_nodepath).text = str(params[0]) if params else ""
	get_node(text_box_nodepath).display_text(text)
	yield(get_node(text_box_nodepath), "advance_text")


func _on_QuicksaveButton_pressed():
#	save_state("res://quicksave.json")
	pass # Replace with function body.

func _on_QuickloadButton_pressed():
	load_state("res://quicksave.json")
	yield(get_node(text_box_nodepath), "advance_text")
	execute_until_yield_or_finished()


