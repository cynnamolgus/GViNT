@tool
extends Object


static func write_file(file_path: String, data: String) -> void:
	var file_access := FileAccess.open(file_path, FileAccess.WRITE)
	if file_access:
		file_access.store_string(data)
		file_access.close()
	else:
		var error_code := FileAccess.get_open_error()
		printerr("Gvint utils: failed to open file '%s' for writing, error code %s" % [file_path, error_code])


static func write_json(file_path: String, data: Variant, indent: String = "") -> void:
	var serialized_data := JSON.stringify(data, indent)
	write_file(file_path, serialized_data)


static func read_json_dict(file_path: String) -> Dictionary:
	var serialized_data = FileAccess.get_file_as_string(file_path)
	var json_dict = JSON.parse_string(serialized_data)
	if json_dict:
		return json_dict
	return {}
