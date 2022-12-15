extends RichTextLabel


signal advance_text
signal queue_emptied


export(float) var characters_per_second = 20.0


var seconds_per_character = 1.0 / characters_per_second

var _character_display_timer := 0.0
var _text_queue := ""


func _input(event):
	if event.is_action_pressed("ui_accept"):
		advance()
		accept_event()


func _physics_process(delta):
	if _text_queue:
		_update_character_timer(delta)
	else:
		_character_display_timer = 0.0


func _update_character_timer(delta: float):
	_character_display_timer += delta
	if _character_display_timer > seconds_per_character:
		_display_next_character()
		_character_display_timer -= seconds_per_character


func _display_next_character():
	append_bbcode(_text_queue[0])
	_text_queue = _text_queue.right(1)
	if not _text_queue:
		emit_signal("queue_emptied")


func display_text(text: String):
	clear()
	append_text(text)


func append_text(text: String):
	_text_queue += text


func flush_queue():
	text += _text_queue
	_text_queue = ""


func clear():
	_text_queue = ""
	.clear()


func advance():
	if _text_queue:
		flush_queue()
	else:
		emit_signal("advance_text")
