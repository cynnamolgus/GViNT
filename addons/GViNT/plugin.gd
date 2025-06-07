@tool
extends EditorPlugin


const MAIN_PANEL = preload("uid://bt8i58p4qooyi")

var main_panel: Gvint.EditorMainPanel


func _ready() -> void:
	_setup_main_panel()

func _exit_tree() -> void:
	_unload_main_panel()

func _get_plugin_name() -> String:
	return "GViNT"

func _has_main_screen() -> bool:
	return true


func _handles(object: Object) -> bool:
	if object is Gvint.ScriptReference:
		main_panel.open_script(object)
		return true
	return false


func _make_visible(visible) -> void:
	if main_panel:
		main_panel.visible = visible


func _setup_main_panel() -> void:
	main_panel = MAIN_PANEL.instantiate()
	main_panel.plugin = self
	EditorInterface.get_editor_main_screen().add_child(main_panel)
	_make_visible(false)


func _unload_main_panel() -> void:
	main_panel.queue_free()
