@tool
extends FileDialog

signal cancelled_or_file_selected(path: String)


func _on_visibility_changed() -> void:
	if not visible:
		cancelled_or_file_selected.emit("")


func _on_file_selected(path: String) -> void:
	cancelled_or_file_selected.emit(path)
