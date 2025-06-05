@tool
extends EditorPlugin


const EDITOR_SCENE = preload("res://addons/GViNT/Editor/gvint_editor.tscn")

var script_editor

@onready var main_screen = EditorInterface.get_editor_main_screen()


func _ready() -> void:
	print("Hello GViNT!")
	_setup_script_editor()

func _exit_tree() -> void:
	print("GViNT exit tree")
	_unload_script_editor()

func _get_plugin_name() -> String:
	return "GViNT"

func _has_main_screen() -> bool:
	return true

func _make_visible(visible) -> void:
	if script_editor:
		script_editor.visible = visible


func _setup_script_editor() -> void:
	script_editor = EDITOR_SCENE.instantiate()
	main_screen.add_child(script_editor)
	_make_visible(false)

func _unload_script_editor() -> void:
	script_editor.queue_free()
