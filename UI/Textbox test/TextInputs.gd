extends VBoxContainer

signal text_submitted
signal text_cleared

onready var text_edit := $TextEdit


func submit_text():
	emit_signal("text_submitted", text_edit.text)
	text_edit.text = ""


func _on_SubmitButton_pressed():
	submit_text()


func _on_ClearButton_pressed():
	emit_signal("text_cleared")
