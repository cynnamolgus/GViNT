extends Reference

static func read_file(file: String) -> String:
	var f := File.new()
	var error = f.open(file, File.READ)
	
	var data: String
	if f.is_open():
		data = f.get_as_text()
		f.close()
	
	return data


static func save_files(directory: String, files: Dictionary) -> Array:
	var saved_files := []
	var d := Directory.new()
	if not d.dir_exists(directory):
		d.make_dir(directory)
	
	var f := File.new()
	for file in files:
		assert(files[file] is String)
		f.open(directory + file, File.WRITE)
		f.store_string(files[file])
		f.close()
		saved_files.append(directory + file)
	return saved_files


static func load_json_dict(file_path: String) -> Dictionary:
	var json_string := read_file(file_path)
	if not json_string:
		return {}
	
	var parse_result := JSON.parse(json_string)
	assert(not parse_result.error)
	
	if parse_result.error:
		push_error(parse_result.error_string)
		return {}
	else:
		return (parse_result.result) as Dictionary


static func delete_directory(directory: String):
	var d = Directory.new()
	if not d.dir_exists(directory):
		return
	var error = d.remove(directory)
	if error:
		error = OS.move_to_trash(ProjectSettings.globalize_path(directory))
	if error:
		push_error("Failed to delete directory '" + directory + "' (error code: " + str(error) + ")")


static func check_calling_method():
	var stack := get_stack()
	if len(stack) <= 2:
		return null
	#index 0 is check_calling_method
	#index 1 is the method that's trying to check what called it
	#index 2 is what it wants to know
	var calling_method = stack[2]["function"]
	return calling_method


static func indent_text_lines(text, indent_amount):
	var lines = text.split("\n")
	var result = ""
	var indentation = ""
	for i in range(indent_amount):
		indentation += "	"
	for line in lines:
		result += indentation + line + "\n"
	return result.trim_suffix("\n")

static func pretty_print_array(arr: Array) -> String:
	var result = "[\n"
	for element in arr:
		result += "	" + str(element) + ",\n	"
	result += "]"
	return result
