tool
extends HBoxContainer

signal selected

const ScriptEditData = preload("res://addons/GViNT/Editor/ScriptEditData.gd")

onready var select_button := $SelectFileButton

var script_data: ScriptEditData setget set_script_data


func set_script_data(new_value):
	script_data = new_value
	script_data.connect("editing_activated", self, "on_script_editing_activated")
	script_data.connect("editing_deactivated", self, "on_script_editing_deactivated")
	script_data.connect("saved", self, "on_script_saved")
	script_data.connect("modified", self, "on_script_modified")
	select_button.text = script_data.file_name


func on_script_saved():
	select_button.text = script_data.file_name
	pass

func on_script_modified():
	select_button.text = script_data.file_name + "(*)"

func on_script_editing_activated(script_data):
	select_button.disabled = true

func on_script_editing_deactivated(script_data):
	select_button.disabled = false


func _on_CloseButton_pressed():
	script_data.close()


func _on_SelectFileButton_pressed():
	emit_signal("selected", script_data)
