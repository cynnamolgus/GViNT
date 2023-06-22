tool
extends Control



func _ready():
	print("GViNT editor ready")


func _on_ClearCacheButton_pressed():
	GvintScripts.clear_cache()
	print("Script cache cleared")
