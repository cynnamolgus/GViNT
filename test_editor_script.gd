tool
extends EditorScript

class Instruction_0:
	pass

class Instruction_1:
	pass

class Instruction_2:
	class Instruction_2_branch0_0:
		pass
	class Instruction_2_branch0_1:
		pass
	class Instruction_2_branch0_2:
		pass
	
	class Instruction_2_branch1_0:
		pass
	class Instruction_2_branch1_1:
		pass
	class Instruction_2_branch1_2:
		pass
	
	static func get_branch0_context():
		return [
			Instruction_2_branch0_0,
			Instruction_2_branch0_1,
			Instruction_2_branch0_2
		]
	
	static func get_branch1_context():
		return [
			Instruction_2_branch1_0,
			Instruction_2_branch1_1,
			Instruction_2_branch1_2
		]
	
	static func execute(runtime):
		if (true):
			runtime.enter_context(get_branch0_context())
		else:
			runtime.enter_context(get_branch1_context())
		pass
	
	pass


class Foo:
	class Bar:
		var x = 42
		static func test():
			print("hello")
		pass


func _run():
	print("a")
#	var foo = Foo.Bar.new()
#	Foo.Bar.test()



