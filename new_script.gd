extends Reference

class Statement_0:
	static func evaluate(runtime: GvintRuntime):
		runtime.foo = 1

class Statement_1:
	static func evaluate(runtime: GvintRuntime):
		runtime.bar = 2

class Statement_2:
	static func evaluate(runtime: GvintRuntime):
		var target = runtime
		assert(target.has_method("do_a_thing"))
		assert(target.has_method("undo_do_a_thing"))
		var result = target.callv("do_a_thing", [])
		if result is GDScriptFunctionState:
			yield(result, "completed")
	
	static func undo(runtime: GvintRuntime):
		var target = runtime
		var result = target.call("undo_do_a_thing")
		if result is GDScriptFunctionState:
			yield(result, "completed")

class Statement_3:
	static func evaluate(runtime: GvintRuntime):
		runtime.foo += 42

class Statement_4:
	static func evaluate(runtime: GvintRuntime):
		runtime.foo = (randi()%2)




static func create_context() -> GvintContext:
	var context = GvintContext.new()
	context.source_filename = "{source_filename}"
	context.instructions = [
	Statement_0,
	Statement_1,
	Statement_2,
	Statement_3,
	Statement_4,
]
	return context
