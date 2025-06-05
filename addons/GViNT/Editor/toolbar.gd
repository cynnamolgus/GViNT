@tool
extends HBoxContainer


func _on_file_manager_file_opened(file: EditorGvintFileData) -> void:
	$SaveButton.disabled = false
	$SaveAsButton.disabled = false
	$CloseFileButton.disabled = false


func _on_file_manager_all_files_closed() -> void:
	$SaveButton.disabled = true
	$SaveAsButton.disabled = true
	$CloseFileButton.disabled = true
