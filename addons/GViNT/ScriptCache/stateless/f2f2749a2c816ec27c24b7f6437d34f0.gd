extends Reference

class Statement_0:
	static func get_id():
		return "0"
	
	static func get_type():
		return "SetVariable"
	
	static func evaluate(runtime: GvintRuntimeStateless):
		var value = "???"
		if value is GDScriptFunctionState:
			value = yield(value, "completed")
		runtime.foo.alias = value

class Statement_1:
	static func get_id():
		return "1"
	
	static func get_type():
		return "SetVariable"
	
	static func evaluate(runtime: GvintRuntimeStateless):
		var value = "???"
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
		var result = target.callv("display_text", ["""Hello, world!""", []])
		if result is GDScriptFunctionState:
			yield(result, "completed")

class Statement_3:
	static func get_id():
		return "3"
	
	static func get_type():
		return "SetVariable"
	
	static func evaluate(runtime: GvintRuntimeStateless):
		var value = runtime.prompt_choice({"A":"foo","B":"bar"})
		if value is GDScriptFunctionState:
			value = yield(value, "completed")
		runtime.player_choice = value

class Statement_4:
	static func get_id():
		return "4"
	
	static func get_type():
		return "IfCondition"
	
	class Statement_4_branch0_0:
		static func get_id():
			return "4_branch0_0"
		
		static func get_type():
			return "CallFunction"
		
		static func evaluate(runtime: GvintRuntimeStateless):
			var target = runtime
			assert(target.has_method("start"))
			var result = target.callv("start", ["foo"])
			if result is GDScriptFunctionState:
				yield(result, "completed")
	
	static func create_branch0_context() -> GvintContext:
		var context = GvintContext.new()
		context.source_filename = "res://Story/start.txt"
		context.statements = [
			Statement_4_branch0_0,
			]
		return context
	
	static func evaluate_conditional(runtime):
		if runtime.player_choice.value=="A":
			return create_branch0_context()



class Statement_5:
	static func get_id():
		return "5"
	
	static func get_type():
		return "IfCondition"
	
	class Statement_5_branch0_0:
		static func get_id():
			return "5_branch0_0"
		
		static func get_type():
			return "CallFunction"
		
		static func evaluate(runtime: GvintRuntimeStateless):
			var target = runtime
			assert(target.has_method("start"))
			var result = target.callv("start", ["bar"])
			if result is GDScriptFunctionState:
				yield(result, "completed")
	
	static func create_branch0_context() -> GvintContext:
		var context = GvintContext.new()
		context.source_filename = "res://Story/start.txt"
		context.statements = [
			Statement_5_branch0_0,
			]
		return context
	
	static func evaluate_conditional(runtime):
		if runtime.player_choice.value=="B":
			return create_branch0_context()



class Statement_6:
	static func get_id():
		return "6"
	
	static func get_type():
		return "CallFunction"
	
	static func evaluate(runtime: GvintRuntimeStateless):
		var target = runtime
		assert(target.has_method("display_text"))
		var result = target.callv("display_text", ["""END""", []])
		if result is GDScriptFunctionState:
			yield(result, "completed")




static func create_context() -> GvintContext:
	var context = GvintContext.new()
	context.source_filename = "res://Story/start.txt"
	context.statements = [
	Statement_0,
	Statement_1,
	Statement_2,
	Statement_3,
	Statement_4,
	Statement_5,
	Statement_6,
	]
	return context
