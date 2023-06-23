extends "res://addons/GViNT/Core/Translator/Statements/Statement.gd"

var keyword: String
var condition: String = ""
var branch_statements = []

func construct_from_tokens(tokens: Array):
	assert(len(tokens) >= 2)
	var first_token = tokens.pop_front()
	assert(
		first_token.type == Tokens.KEYWORD_IF
		or first_token.type == Tokens.KEYWORD_ELSE
		or first_token.type == Tokens.KEYWORD_ELIF
	)
	
	var last_token = tokens.pop_back()
	assert(last_token.type == Tokens.OPEN_BRACE)
	
	keyword = first_token.text
	
	for t in tokens:
		condition += t.text
