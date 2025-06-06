@tool
class_name EditorGvintEditor extends PanelContainer


var plugin: EditorPlugin:
	set(value):
		plugin = value
		$FileManager.plugin = value


func open_script(script_reference: GvintScriptReference):
	$FileManager.open_file_and_set_current(script_reference.resource_path)
