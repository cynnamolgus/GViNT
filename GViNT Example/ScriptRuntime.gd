extends GvintRuntimeStateful


export(NodePath) var text_box_nodepath
export(NodePath) var name_label_nodepath



func _init_runtime_variables():
	create_runtime_variable("number", 1337)


func display_text(text: String, params: Array):
	print(str(params) + ": " + text)
	get_node(name_label_nodepath).text = str(params[0]) if params else ""
	get_node(text_box_nodepath).display_text(text)
	yield(get_node(text_box_nodepath), "advance_text")


func _on_QuicksaveButton_pressed():
	save_state("res://quicksave.json")


func _on_QuickloadButton_pressed():
	load_state("res://quicksave.json")
	prevent_undo()
	yield(get_node(text_box_nodepath), "advance_text")
	execute_until_yield_or_finished()


func _save_state() -> Dictionary:
	return {
		"name": get_node(name_label_nodepath).text,
		"text": get_node(text_box_nodepath).text,
	}


func _load_state(savestate: Dictionary):
	get_node(name_label_nodepath).text = savestate.name
	get_node(text_box_nodepath).text = savestate.text


