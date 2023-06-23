extends LineEdit

var number_variable: GvintVariable





func _on_LineEdit_text_changed(new_text):
	if number_variable:
		number_variable.stateless_set(int(new_text))
	pass # Replace with function body.
