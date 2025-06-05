@tool
class_name EditorGvintUtils


static func write_file(file_path: String, data: String) -> void:
	var file_access := FileAccess.open(file_path, FileAccess.WRITE)
	if file_access:
		file_access.store_string(data)
		file_access.close()
	else:
		var error_code := file_access.get_open_error()
		printerr("Gvint utils: failed to open file '%s' for writing, error code %s" % [file_path, error_code])
