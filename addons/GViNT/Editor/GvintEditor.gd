tool
extends Control

onready var script_editor = find_node("ScriptEditor")

var plugin: EditorPlugin setget set_plugin

func set_plugin(new_value):
	plugin = new_value
	script_editor.plugin = plugin


func _ready():
	print("GViNT editor ready")
#	$VBoxContainer/PanelContainer/NewFileDialog.popup_centered_clamped()


func _on_ClearCacheButton_pressed():
	GvintScripts.clear_cache()
	print("Script cache cleared")
