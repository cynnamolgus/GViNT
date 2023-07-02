tool
extends EditorScript

class Foo:
	func _init():
		print("foo init")

class Bar extends Foo:
	func _init():
		print("bar init")

func _run():
	var foo = Bar.new()
	pass


