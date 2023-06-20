extends Reference



const Tokens = preload("res://addons/GViNT/Core/Translator/Tokenizer/Tokens.gd")
const ScriptTemplates = preload("res://addons/GViNT/Core/Translator/Templates/ScriptTemplates.gd")
const Templates = preload("res://addons/GViNT/Core/Translator/Templates/Templates.gd")
const GvintUtils = preload("res://addons/GViNT/Core/Utils.gd")

var statement_id := ""
var template: String



func construct_from_tokens(tokens: Array):
	pass
