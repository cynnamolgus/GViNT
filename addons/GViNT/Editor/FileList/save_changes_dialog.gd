@tool
extends AcceptDialog


signal save_and_close_requested
signal force_close_requested


func _ready():
	add_button("Close without saving", false, "force_close_requested")
	add_button("Save & close", false, "save_and_close_requested")


func _on_custom_action(action: StringName) -> void:
	hide()
	match action:
		"save_and_close_requested":
			save_and_close_requested.emit()
		"force_close_requested":
			force_close_requested.emit()
