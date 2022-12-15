tool
extends Control



func _ready():
	print("GViNT editor ready")


func _on_ClearCacheButton_pressed():
	GvintScripts.clear_script_info()
	print("Script cache cleared")
