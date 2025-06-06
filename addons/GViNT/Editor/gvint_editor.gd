@tool
class_name EditorGvintEditor extends PanelContainer


var plugin: EditorPlugin:
	set(value):
		plugin = value
		$FileManager.plugin = value
		$HotkeyManager.plugin = value


func open_script(script_reference: EditorGvintScriptReference):
	$FileManager.open_file_and_set_current(script_reference.resource_path)
