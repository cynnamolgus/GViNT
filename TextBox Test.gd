extends Control

const GvintUtils = preload("res://addons/GViNT/Core/Utils.gd")
const Translator = preload("res://addons/GViNT/Core/Translator/Translator.gd")

const DEFAULT_CONFIG_FILE = "res://addons/GViNT/Core/default_script_config.json" 

var translator := Translator.new()

var source_code = """
if true {
foo = 5
} elif foo {
foo = 10
}
"""

func _ready():
	var config = GvintUtils.load_json_dict(DEFAULT_CONFIG_FILE)
	var result = translator.translate_source_code(source_code, config)
	print(result)
	pass # Replace with function body.

