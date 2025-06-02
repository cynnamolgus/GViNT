@tool
extends HBoxContainer

@onready var filename_label := $FilenameLabel
@onready var caret_label := $CaretLabel

var filename := "<No file open>"

var caret_line: int = -1:
	set(value):
		var should_update: bool = (caret_line != value)
		caret_line = value
		if should_update:
			update_caret_label()

var caret_position: int = -1:
	set(value):
		var should_update: bool = (caret_line != value)
		caret_position = value
		if should_update:
			update_caret_label()


func update_caret_label():
	caret_label.text = "line %s - position %s" % [caret_line, caret_position]
