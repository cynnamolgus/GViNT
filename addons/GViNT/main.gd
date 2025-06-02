@tool
extends EditorPlugin

const GvintScriptEditor = preload("res://addons/GViNT/Editor/script_editor.tscn")

@onready var main_screen = EditorInterface.get_editor_main_screen()
var script_editor


func _has_main_screen():
	return true

func _get_plugin_name():
	return "GViNT"


func _ready():
	print("Hello GViNT!")
	_setup_script_editor()

func _exit_tree() -> void:
	print("GViNT exit tree")
	_unload_script_editor()

func _make_visible(visible):
	if script_editor:
		script_editor.visible = visible


func _setup_script_editor():
	script_editor = GvintScriptEditor.instantiate()
	main_screen.add_child(script_editor)
	_make_visible(false)

func _unload_script_editor():
	script_editor.queue_free()
