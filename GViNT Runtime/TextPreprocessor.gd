extends Node

export(NodePath) var textbox_path
onready var textbox = get_node(textbox_path)
export(NodePath) var name_label_path
onready var name_label = get_node(name_label_path)


func display_text(text: String, params: Array):
	textbox.display_text(text)
	if params:
		if params[0] is GvintVariable:
			name_label.text = str(params[0].value)
		else:
			name_label.text = str(params[0])
	else:
		name_label.text = ""
	yield(textbox, "advance_text")


func undo_display_text():
	pass
