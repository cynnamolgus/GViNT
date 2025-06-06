@tool
class_name EditorGvintStatusBar extends HBoxContainer


var file_path := "<No file open>":
	set(value):
		file_path = value
		$FilePathLabel.text = file_path

var caret_line: int = -1:
	set(value):
		caret_line = value
		update_caret_label()

var caret_position: int = -1:
	set(value):
		caret_position = value
		update_caret_label()

@onready var caret_label := $CaretLabel


func _ready() -> void:
	update_caret_label()


func update_caret_label() -> void:
	caret_label.text = "%s: %s" % [caret_line, caret_position]
