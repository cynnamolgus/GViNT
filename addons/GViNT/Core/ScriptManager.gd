tool
extends Node


const SCRIPT_INFO_FILE = "res://addons/GViNT/Config/scripts.json"

const Translator = preload("res://addons/GViNT/Core/Translator/Translator.gd")


var translator := Translator.new()
var script_info := {}


func _ready():
	load_script_info()


func load_script_info():
	
	pass


func load_script(source_filename: String) -> GvintContext:
	
	return null





