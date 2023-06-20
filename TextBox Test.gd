extends Control

const GvintUtils = preload("res://addons/GViNT/Core/Utils.gd")
const Translator = preload("res://addons/GViNT/Core/Translator/Translator.gd")

const DEFAULT_CONFIG_FILE = "res://addons/GViNT/Core/default_script_config.json" 

var translator := Translator.new()

var source_code = """
foo = 1
bar = 2
do_a_thing()
foo += 42
foo = (randi() % 2)
"""

func _ready():
	var config = GvintUtils.load_json_dict(DEFAULT_CONFIG_FILE)
	var result = translator.translate_source_code(source_code, config)
	print(result)
	pass # Replace with function body.

