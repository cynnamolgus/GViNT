@tool
extends HBoxContainer


func _on_file_manager_current_file_changed(file: EditorGvintFileData) -> void:
	if file:
		$SaveButton.disabled = false
		$SaveAsButton.disabled = false
		$CloseFileButton.disabled = false
	else:
		$SaveButton.disabled = true
		$SaveAsButton.disabled = true
		$CloseFileButton.disabled = true
