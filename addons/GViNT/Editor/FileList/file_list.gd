@tool
extends ItemList


signal move_current_file_requested(to_index: int)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if (
			data is Dictionary
			and "type" in data
			and data.type == "gvint_filelist_item"
	):
		return true
	return false


func _get_drag_data(_at_position: Vector2) -> Variant:
	var selected_items := get_selected_items()
	if selected_items:
		assert(selected_items.size() == 1)
		var dragged_item := selected_items[0]
		var preview := Label.new()
		preview.modulate.a = 0.5
		preview.text = get_item_text(dragged_item)
		set_drag_preview(preview)
		return {
			"type": "gvint_filelist_item",
			#"gvint_filelist_item": dragged_item,
		}
	return null


func _drop_data(at_position: Vector2, _data: Variant) -> void:
	var drop_index := get_item_at_position(at_position)
	move_current_file_requested.emit(drop_index)


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
