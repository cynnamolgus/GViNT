extends Reference

const MODE_STATELESS = "STATELESS"
const MODE_STATEFUL = "STATEFUL"

var id := "default"
var mode = MODE_STATELESS

var display_text_target = "runtime"
var display_text_method = "display_text"

var undo_method_prefix = "undo_"

var shorthands := {
	#"play_sound": "audio.play_sound" etc
}

func load_from_json_object(data: Dictionary):
	id = data.id
	mode = data.mode
	display_text_target = data.display_text_target
	display_text_method = data.display_text_method
	undo_method_prefix = data.undo_method_prefix
	shorthands = data.shorthands

func to_json_object():
	var result = {}
	result.id = id
	result.mode = mode
	result.display_text_target = display_text_target
	result.display_text_method = display_text_method
	result.undo_method_prefix = undo_method_prefix
	result.shorthands = shorthands

