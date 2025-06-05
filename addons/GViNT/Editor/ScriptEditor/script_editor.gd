@tool
extends VBoxContainer

@onready var code_edit: CodeEdit = $CodeEdit
@onready var status_bar: EditorGvintStatusBar = $StatusBar


func _on_code_edit_caret_changed() -> void:
	status_bar.caret_line = code_edit.get_caret_line()
	status_bar.caret_position = code_edit.get_caret_column()
