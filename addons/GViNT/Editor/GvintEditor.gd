tool
extends Control



func _ready():
	print("GViNT editor ready")
#	$VBoxContainer/PanelContainer/NewFileDialog.popup_centered_clamped()


func _on_ClearCacheButton_pressed():
	GvintScripts.clear_cache()
	print("Script cache cleared")
