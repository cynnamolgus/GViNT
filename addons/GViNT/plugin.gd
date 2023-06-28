tool
extends EditorPlugin



const GvintEditorScene = preload("res://addons/GViNT/Editor/GvintEditor.tscn")
const SCRIPT_MANAGER = "res://addons/GViNT/Autoload/GvintScripts.tscn"


var ui_root: Control
var interface: EditorInterface



func _init():
	interface = get_editor_interface()


func _enter_tree():
	spawn_script_manager()
	spawn_ui()
	make_visible(false)


func _exit_tree():
	remove_ui()
	remove_script_manager()


func has_main_screen():
	return true

func make_visible(visible):
	if is_instance_valid(ui_root):
		ui_root.visible = visible
	elif visible:
		spawn_ui()
		make_visible(true)

func get_plugin_name():
	return "GViNT"

func get_plugin_icon():
	return get_editor_interface().get_base_control().get_icon(
		"Node",
		"EditorIcons"
	)


#func handles(object):
#	if object is GvintRuntime:
#		return true


func spawn_ui():
	ui_root = GvintEditorScene.instance()
	interface.get_editor_viewport().add_child(ui_root)
	ui_root.plugin = self

func remove_ui():
	if is_instance_valid(ui_root):
		ui_root.queue_free()


func spawn_script_manager():
	add_autoload_singleton(
		"GvintScripts",
		SCRIPT_MANAGER
	)

func remove_script_manager():
	remove_autoload_singleton("GvintScripts")
