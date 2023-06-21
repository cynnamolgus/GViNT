extends Reference

class Statement_0:
	class Statement_0_branch0_0:
		static func evaluate(runtime: GvintRuntime):
			runtime.foo = 5
	
	class Statement_0_branch1_0:
		static func evaluate(runtime: GvintRuntime):
			runtime.foo = 10
	
	static func create_branch0_context() -> GvintContext:
		var context = GvintContext.new()
		context.source_filename = "{source_filename}"
		context.instructions = [
			Statement_0_branch0_0,
			]
		return context
	
	static func create_branch1_context() -> GvintContext:
		var context = GvintContext.new()
		context.source_filename = "{source_filename}"
		context.instructions = [
			Statement_0_branch1_0,
			]
		return context
	

	static func evaluate(runtime: GvintRuntime):
		if true:
			return create_branch0_context()
		




static func create_context() -> GvintContext:
	var context = GvintContext.new()
	context.source_filename = "{source_filename}"
	context.instructions = [
	Statement_0,
	]
	return context
