extends "res://GViNT/Translator/Parser/ParseNode.gd"


var current_phrase = self

var actions := []

func parse_instructions(tokens: Array) -> Array:
	for token in tokens:
		if token.type != Tokens.END_OF_FILE:
			current_phrase.append_token(token)
		else:
			assert(token == tokens.back())
			break
	return actions


func consumes_token(token: Token):
	return false


func get_child_type_spawned_by_token(token: Token):
	match token.type:
		Tokens.IDENTIFIER:
			pass
		Tokens.STRING:
			pass
		Tokens.INLINE_TEXT:
			pass
		Tokens.KEYWORD_IF:
			pass
		Tokens.KEYWORD_ELSE:
			pass
		Tokens.KEYWORD_ELIF:
			pass
		Tokens.KEYWORD_RETURN:
			pass


func terminated_by_token(token: Token):
	return false


func on_child_phrase_terminated():
	pass
