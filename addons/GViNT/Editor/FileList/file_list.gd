@tool
extends ItemList


func toggle_visible() -> void:
	if visible:
		hide()
	else:
		show()


func update_displayed_filename(file: Gvint.EditorFile) -> void:
	set_item_text(
			file.manager_index, 
			file.filename \
					+ ("(*)" if file.has_unsaved_changes else "")
	)


func _on_file_manager_file_opened(file: Gvint.EditorFile) -> void:
	file.filename_changed.connect(update_displayed_filename.bind(file))
	file.modified_status_changed.connect(update_displayed_filename.bind(file))
	add_item(file.filename)


func _on_file_manager_current_file_changed(file: Gvint.EditorFile) -> void:
	if file:
		select(file.manager_index)


func _on_file_manager_file_index_closed(index: int) -> void:
	remove_item(index)
	if index == 0 and item_count > 0:
		select(0)


func _on_item_clicked(index: int, _at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		select(index)
		item_selected.emit(index)
		$FileContextMenu.position = DisplayServer.mouse_get_position()
		$FileContextMenu.show()


func _on_file_manager_file_index_moved(from: int, to: int) -> void:
	move_item(from, to)
