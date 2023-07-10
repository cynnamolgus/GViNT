extends Reference

class Statement_0:
	static func get_id():
		return "0"
	
	static func get_type():
		return "SetVariable"
	
	static func evaluate(runtime: GvintRuntimeStateful):
		var target = runtime.foo.alias
		assert(target is GvintVariable)
		var value = "???"
		if value is GDScriptFunctionState:
			value = yield(value, "completed")
		target.value = value
	
	static func undo(runtime: GvintRuntimeStateful):
		var target = runtime.foo.alias
		assert(target is GvintVariable)
		target.undo_last_change()

class Statement_1:
	static func get_id():
		return "1"
	
	static func get_type():
		return "SetVariable"
	
	static func evaluate(runtime: GvintRuntimeStateful):
		var target = runtime.bar.alias
		assert(target is GvintVariable)
		var value = "???"
		if value is GDScriptFunctionState:
			value = yield(value, "completed")
		target.value = value
	
	static func undo(runtime: GvintRuntimeStateful):
		var target = runtime.bar.alias
		assert(target is GvintVariable)
		target.undo_last_change()

class Statement_2:
	static func get_id():
		return "2"
	
	static func get_type():
		return "CallFunction"
	
	static func evaluate(runtime: GvintRuntimeStateful):
		var target = runtime
		assert(target.has_method("display_text"))
		var result = target.callv("display_text", ["""Hello, world!""", []])
		if result is GDScriptFunctionState:
			yield(result, "completed")
	
	static func undo(runtime: GvintRuntimeStateful):
		var target = runtime
		if target.has_method("undo_display_text"):
			var result = target.call("undo_display_text")
			if result is GDScriptFunctionState:
				yield(result, "completed")

class Statement_3:
	static func get_id():
		return "3"
	
	static func get_type():
		return "SetVariable"
	
	static func evaluate(runtime: GvintRuntimeStateful):
		var target = runtime.player_choice
		assert(target is GvintVariable)
		var value = runtime.prompt_choice({"A":"foo","B":"bar"})
		if value is GDScriptFunctionState:
			value = yield(value, "completed")
		target.value = value
	
	static func undo(runtime: GvintRuntimeStateful):
		var target = runtime.player_choice
		assert(target is GvintVariable)
		target.undo_last_change()

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
		
		static func evaluate(runtime: GvintRuntimeStateful):
			var target = runtime
			assert(target.has_method("start"))
			var result = target.callv("start", ["foo"])
			if result is GDScriptFunctionState:
				yield(result, "completed")
		
		static func undo(runtime: GvintRuntimeStateful):
			var target = runtime
			if target.has_method("undo_start"):
				var result = target.call("undo_start")
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
		
		static func evaluate(runtime: GvintRuntimeStateful):
			var target = runtime
			assert(target.has_method("start"))
			var result = target.callv("start", ["bar"])
			if result is GDScriptFunctionState:
				yield(result, "completed")
		
		static func undo(runtime: GvintRuntimeStateful):
			var target = runtime
			if target.has_method("undo_start"):
				var result = target.call("undo_start")
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
	
	static func evaluate(runtime: GvintRuntimeStateful):
		var target = runtime
		assert(target.has_method("display_text"))
		var result = target.callv("display_text", ["""END""", []])
		if result is GDScriptFunctionState:
			yield(result, "completed")
	
	static func undo(runtime: GvintRuntimeStateful):
		var target = runtime
		if target.has_method("undo_display_text"):
			var result = target.call("undo_display_text")
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
