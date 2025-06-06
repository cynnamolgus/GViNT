@tool
extends PanelContainer

var plugin: EditorPlugin:
	set(value):
		plugin = value
		$FileManager.plugin = value
