@tool
extends PanelContainer


var plugin: EditorPlugin:
	set(value):
		plugin = value
		$FileManager.plugin = value
		$HotkeyManager.plugin = value
		$VBoxContainer/Toolbar.plugin = value
		$VBoxContainer/HSplitContainer/FileList/FileContextMenu.plugin = value


func open_script(script_reference: Gvint.ScriptReference):
	$FileManager.open_file_and_set_current(script_reference.resource_path)
