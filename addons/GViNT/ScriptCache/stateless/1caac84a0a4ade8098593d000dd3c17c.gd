extends Reference

class Statement_0:
	static func get_id():
		return "0"
	
	static func get_type():
		return "CallFunction"
	
	static func evaluate(runtime: GvintRuntimeStateless):
		var target = runtime
		assert(target.has_method("display_text"))
		var result = target.callv("display_text", ["""Lorem ipsum""", [runtime.bar]])
		if result is GDScriptFunctionState:
			yield(result, "completed")

class Statement_1:
	static func get_id():
		return "1"
	
	static func get_type():
		return "SetVariable"
	
	static func evaluate(runtime: GvintRuntimeStateless):
		var value = "Bar"
		if value is GDScriptFunctionState:
			value = yield(value, "completed")
		runtime.bar.alias = value

class Statement_2:
	static func get_id():
		return "2"
	
	static func get_type():
		return "CallFunction"
	
	static func evaluate(runtime: GvintRuntimeStateless):
		var target = runtime
		assert(target.has_method("display_text"))
		var result = target.callv("display_text", ["""dolor sit amet,""", [runtime.bar]])
		if result is GDScriptFunctionState:
			yield(result, "completed")

class Statement_3:
	static func get_id():
		return "3"
	
	static func get_type():
		return "CallFunction"
	
	static func evaluate(runtime: GvintRuntimeStateless):
		var target = runtime
		assert(target.has_method("display_text"))
		var result = target.callv("display_text", ["""consectetur adipiscing elit.""", [runtime.bar]])
		if result is GDScriptFunctionState:
			yield(result, "completed")




static func create_context() -> GvintContext:
	var context = GvintContext.new()
	context.source_filename = "res://Story/bar.txt"
	context.statements = [
	Statement_0,
	Statement_1,
	Statement_2,
	Statement_3,
	]
	return context
