@tool
extends VBoxContainer


var current_file: EditorGvintFileData

@onready var status_bar: EditorGvintStatusBar = $StatusBar
@onready var current_code_edit: CodeEdit = $CodeEdit


func _on_file_manager_current_file_changed(file: EditorGvintFileData) -> void:
	if not is_node_ready():
		await ready
	current_code_edit.hide()
	if file:
		current_file = file
		current_code_edit = current_file.code_edit
		status_bar.filename = current_file.filename
		status_bar.caret_line = current_code_edit.get_caret_line()
		status_bar.caret_position = current_code_edit.get_caret_column()
	else:
		current_file = null
		current_code_edit = $CodeEdit
		status_bar.filename = "<No file open>"
		status_bar.caret_line = -1
		status_bar.caret_position = -1
	current_code_edit.show()


func _on_file_manager_file_opened(file: EditorGvintFileData) -> void:
	_setup_code_edit(file.code_edit)
	file.filename_changed.connect(_on_file_filename_changed)


func _setup_code_edit(code_edit: EditorGvintCodeEdit) -> void:
	add_child(code_edit)
	move_child(code_edit, 0)
	code_edit.caret_changed.connect(_on_code_edit_caret_changed)


func _on_file_filename_changed() -> void:
	status_bar.filename = current_file.filename


func _on_code_edit_caret_changed() -> void:
	status_bar.caret_line = current_code_edit.get_caret_line()
	status_bar.caret_position = current_code_edit.get_caret_column()
