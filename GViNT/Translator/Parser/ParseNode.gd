extends Reference

const Token = preload("res://GViNT/Translator/Tokenizer/Token.gd")
const Tokens = preload("res://GViNT/Translator/Tokenizer/Tokens.gd")


var root = self
var parent
var children := []

var error: String = ""

var last_child
var terminated: bool = false


func add_child(child):
	if "root" in child:
		child.root = root
		child.parent = self
	children.append(child)

func remove_child(child):
	children.erase(child)


func terminated_by_token(token: Token):
	pass

func consumes_token(token: Token):
	pass

func get_child_type_spawned_by_token(token: Token):
	pass

func check_error():
	pass

func on_child_phrase_terminated():
	pass


func append_token(token: Token):
	assert(not terminated)
	var child_type = get_child_type_spawned_by_token(token)
	if child_type != null:
		spawn_child(child_type, token)
	elif terminated_by_token(token):
		terminate(token)
	elif consumes_token(token):
		consume_token(token)
	else:
		assert(false, "parser logic error: node must consume token, spawn child, or terminate")


func spawn_child(type, token: Token):
	var child = type.new()
	add_child(child)
	child.append_token(token)


func terminate(token: Token = null):
	assert(not children.empty())
	terminated = true
	parent.on_child_phrase_terminated()
	if token:
		parent.append_token(token)


func consume_token(token: Token):
	add_child(token)
	root.current_phrase = self

