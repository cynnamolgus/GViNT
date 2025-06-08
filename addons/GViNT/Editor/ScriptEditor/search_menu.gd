@tool
extends PanelContainer

const NO_MATCH = Vector2i(-1, -1)

var current_code_edit: Gvint.EditorCodeEdit:
	set = set_current_code_edit

var search_text: String
var search_flags: int
var search_whole_words: bool = false
var search_match_case: bool = false

var search_occurences: Array[Vector2i] = []
var search_occurence_index_before_caret: int = 0

@onready var search_controls := $VBoxContainer/SearchControls
@onready var search_text_edit := $VBoxContainer/SearchControls/SearchTextEdit
@onready var replace_controls := $VBoxContainer/ReplaceControls
@onready var replace_text_edit := $VBoxContainer/ReplaceControls/ReplaceTextEdit
@onready var status_label := $VBoxContainer/SearchControls/StatusLabel



func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventKey:
		if (
				event.keycode == KEY_ESCAPE and event.pressed and (
						search_text_edit.has_focus()
						or replace_text_edit.has_focus()
				)
		):
			hide()


func set_current_code_edit(value: Gvint.EditorCodeEdit) -> void:
	var previous_code_edit := current_code_edit
	current_code_edit = value
	if current_code_edit:
		if is_visible_in_tree():
			current_code_edit.set_search_text(search_text)
		current_code_edit.text_changed.connect(_on_current_text_edit_text_changed)
		current_code_edit.caret_changed.connect(_on_current_text_edit_caret_changed)
		update_search_occurences()
	else:
		hide()
	
	if previous_code_edit:
		previous_code_edit.set_search_text("")
		previous_code_edit.text_changed.disconnect(_on_current_text_edit_text_changed)
		previous_code_edit.caret_changed.disconnect(_on_current_text_edit_caret_changed)


func update_search_flags() -> void:
	search_flags = (TextEdit.SEARCH_MATCH_CASE if search_match_case else 0) \
			+ (TextEdit.SEARCH_WHOLE_WORDS if search_whole_words else 0)
	current_code_edit.set_search_flags(search_flags)
	current_code_edit.queue_redraw()
	update_search_occurences()
	update_status_label()


func update_search_occurences() -> void:
	search_occurences = []
	if search_text == "":
		update_status_label()
		return
	
	var first_occurence := _search_next_occurence(Vector2i(0, 0))
	
	if first_occurence == NO_MATCH:
		update_status_label()
		return
	
	search_occurences = [first_occurence]
	var next_occurence := current_code_edit.search(
			search_text,
			search_flags,
			first_occurence.y,
			first_occurence.x + search_text.length()
	)
	var previous_occurence := first_occurence
	var should_break := false
	while true:
		if next_occurence.y == previous_occurence.y:
			should_break = next_occurence.x <= previous_occurence.x
		else:
			should_break = next_occurence.y < previous_occurence.y
		
		if should_break:
			break
		
		search_occurences.append(next_occurence)
		previous_occurence = next_occurence
		next_occurence = current_code_edit.search(
				search_text,
				search_flags,
				next_occurence.y,
				next_occurence.x + search_text.length()
		)
	update_status_label()


func update_status_label() -> void:
	var caret_position: Vector2i = Vector2i(
			current_code_edit.get_caret_column(),
			current_code_edit.get_caret_line()
	)
	if search_occurences.is_empty():
		status_label.text = "0/0"
	
	search_occurence_index_before_caret = 0
	for search_occurence in search_occurences:
		if search_occurence.y < caret_position.y:
			search_occurence_index_before_caret += 1
			continue
		if search_occurence.y == caret_position.y:
			if search_occurence.x >= caret_position.x:
				break
			else:
				search_occurence_index_before_caret += 1
				continue
		if search_occurence.y > caret_position.y:
			break
	
	status_label.text = "%s/%s" % [search_occurence_index_before_caret, search_occurences.size()]
	


func search_next() -> void:
	_search_and_select_text(false)


func search_previous() -> void:
	_search_and_select_text(true)


func replace_occurence() -> void:
	if search_occurences.size() == 0:
		return
	
	var search_occurence: Vector2i
	if search_occurence_index_before_caret <= 1:
		search_occurence = search_occurences[0]
	else:
		search_occurence = search_occurences[search_occurence_index_before_caret - 1]
	
	current_code_edit.begin_complex_operation()
	_select_occurence(search_occurence)
	current_code_edit.delete_selection()
	current_code_edit.insert_text_at_caret(replace_text_edit.text)
	current_code_edit.end_complex_operation()
	
	# if there's still any search text occurences, select the next one -
	# search_occurences only updates after the CodeEdit emits 
	# text_changed, which doesn't happen directly after the replace operation
	# (there's probably some deferred call involved in the TextEdit internals)
	# so, if there's no more search occurences, the search_occurence
	# array will lag behind and still have 1 element here
	if search_occurences.size() > 1:
		_search_and_select_text(false)


func replace_all_occurences() -> void:
	if search_occurences.size() == 0:
		return
	
	current_code_edit.begin_complex_operation()
	current_code_edit.set_caret_line(0)
	current_code_edit.set_caret_column(0)
	var next_occurence := _search_next_occurence(Vector2i(0, 0))
	while next_occurence != NO_MATCH:
		_select_occurence(next_occurence)
		current_code_edit.insert_text_at_caret(replace_text_edit.text)
		next_occurence = _search_next_occurence(next_occurence)
	current_code_edit.end_complex_operation()


func show_search_controls() -> void:
	if not current_code_edit:
		return
	search_text_edit.grab_focus()
	search_controls.show()
	replace_controls.hide()
	show()


func show_search_and_replace_controls() -> void:
	if not current_code_edit:
		return
	search_text_edit.grab_focus()
	search_controls.show()
	replace_controls.show()
	show()


func _search_and_select_text(backwards: bool) -> void:
	if search_occurences.size() == 0:
		return
	var search_from_column := current_code_edit.get_caret_column()
	if backwards:
		search_from_column -= search_text.length() + 1
		search_from_column = max(search_from_column, 0)
	var search_occurence := _search_next_occurence(
			Vector2i(search_from_column, current_code_edit.get_caret_line()),
			backwards
	)
	assert(search_occurence != NO_MATCH)
	_select_occurence(search_occurence)
	current_code_edit.center_viewport_to_caret()


func _search_next_occurence(after_position: Vector2i, search_backwards: bool = false) -> Vector2i:
	return current_code_edit.search(
			search_text,
			search_flags + (TextEdit.SEARCH_BACKWARDS if search_backwards else 0),
			after_position.y,
			after_position.x
	)


func _select_occurence(search_occurence: Vector2i) -> void:
	current_code_edit.select(
			search_occurence.y,
			search_occurence.x,
			search_occurence.y,
			search_occurence.x + search_text.length()
	)


func _on_visibility_changed() -> void:
	if current_code_edit:
		if is_visible_in_tree():
			current_code_edit.set_search_text(search_text)
			search_text_edit.select_all()
		else:
			current_code_edit.set_search_text("")
	pass


func _on_search_text_edit_text_changed(new_text: String) -> void:
	search_text = new_text
	if not search_text:
		current_code_edit.deselect()
	current_code_edit.set_search_text(new_text)
	current_code_edit.queue_redraw()
	update_search_occurences()


func _on_search_text_edit_text_submitted(_new_text: String) -> void:
	if Input.is_key_pressed(KEY_SHIFT):
		search_previous()
	else:
		search_next()
	search_text_edit.grab_focus()


func _on_replace_text_edit_text_submitted(_new_text: String) -> void:
	replace_occurence()


func _on_match_case_check_box_toggled(toggled_on: bool) -> void:
	search_match_case = toggled_on
	update_search_flags()


func _on_whole_word_check_box_toggled(toggled_on: bool) -> void:
	search_whole_words = toggled_on
	update_search_flags()


func _on_current_text_edit_text_changed() -> void:
	if is_visible_in_tree():
		update_search_occurences()


func _on_current_text_edit_caret_changed() -> void:
	if is_visible_in_tree():
		update_status_label()
