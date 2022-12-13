class_name GvintContextLoader extends Reference

static func get_instructions() -> Array:
	return []

static func get_source_filename() -> String:
	return ""

static func get_context():
	var context = GvintContext.new()
	context.source_filename = get_source_filename()
	context.instructions = get_instructions()
	pass
