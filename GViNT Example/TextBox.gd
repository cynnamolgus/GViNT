extends PanelContainer

const Character = preload("res://GViNT Example/Character.gd")

onready var portrait_container = $HBoxContainer/PortraitContainer
onready var name_label = $HBoxContainer/PortraitContainer/VBoxContainer/Label
onready var portrait = $HBoxContainer/PortraitContainer/VBoxContainer/TextureRect
onready var queued_label = $HBoxContainer/MarginContainer/RichTextLabel


func display_text(text: String, character: Character = null):
	if character:
		name_label.text = character.alias
		portrait.texture = character.portrait
		portrait_container.show()
	else:
		portrait_container.hide()
	queued_label.display_text(text)
