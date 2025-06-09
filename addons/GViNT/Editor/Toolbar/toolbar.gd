@tool
extends HBoxContainer


var plugin: EditorPlugin:
	set(value):
		plugin = value
		$FileMenuButton.plugin = plugin
		$SearchMenuButton.plugin = plugin
		$ViewMenuButton.plugin = plugin
