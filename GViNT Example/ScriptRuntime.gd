extends GvintRuntimeStateful

signal script_step_input_received
signal player_choice_taken

const Character = preload("res://GViNT Example/Character.gd")
const TextBox = preload("res://GViNT Example/TextBox.gd")


onready var text_box: TextBox = $"../TextBox"
onready var side_menu = $"../SideMenu"
onready var choice_menu = $"../ChoiceMenu"


onready var foo: Character = $Foo
onready var bar: Character = $Bar



func _on_QuicksaveButton_pressed():
	save_state("res://GViNT Example/quicksave.json")


func _on_QuickloadButton_pressed():
	load_state("res://GViNT Example/quicksave.json")
	prevent_undo()
	if not undo_limit_reached():
		var input = yield(self, "script_step_input_received")
		if input == "advance":
			execute_until_yield_or_finished()
	else:
		yield(text_box.queued_label, "advance_text")
		execute_until_yield_or_finished()


func _on_AdvanceButton_pressed():
	text_box.queued_label.advance()


func _on_RichTextLabel_advance_text():
	emit_signal("script_step_input_received", "advance")


func _on_UndoButton_pressed():
	emit_signal("script_step_input_received", "undo")


func _on_choice_button_pressed(choice: String):
	emit_signal("player_choice_taken", choice)


func _save_state() -> Dictionary:
	return {
		"name": text_box.name_label.text,
		"text": text_box.queued_label.text,
		"portrait": text_box.portrait.texture.resource_path,
		"foo_alias": foo.alias.serialize_state(),
		"bar_alias": bar.alias.serialize_state(),
	}


func _load_state(savestate: Dictionary):
	text_box.name_label.text = savestate.name
	text_box.queued_label.text = savestate.text
	text_box.portrait.texture = load(savestate.portrait)
	if savestate.name:
		text_box.portrait_container.show()
	else:
		text_box.portrait_container.hide()
	foo.alias = GvintVariable.new()
	foo.alias.load_state(savestate.foo_alias)
	bar.alias = GvintVariable.new()
	bar.alias.load_state(savestate.bar_alias)



func _on_script_execution_starting():
	foo.alias = GvintVariable.new()
	bar.alias = GvintVariable.new()


func display_text(text: String, params: Array):
	print(str(params) + ": " + text)
	
	var character = (params[0] as Character) if params else null
	text_box.display_text(text, character)
	yield(text_box.queued_label, "advance_text")


func prompt_choice(choices: Dictionary):
	for choice_value in choices:
		var button = Button.new()
		button.text = choices[choice_value]
		button.connect("pressed", self, "_on_choice_button_pressed", [choice_value])
		choice_menu.add_child(button)
	
	text_box.hide()
	side_menu.hide()
	
	var choice = yield(self, "player_choice_taken")
	
	text_box.show()
	side_menu.show()
	
	for child_index in choice_menu.get_child_count():
		choice_menu.get_child(child_index).queue_free()
	return choice

