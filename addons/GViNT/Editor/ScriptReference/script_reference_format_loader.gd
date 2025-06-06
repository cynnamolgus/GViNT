@tool
class_name EditorGvintScriptReferenceFormatLoader extends ResourceFormatLoader


func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["gvint"])


func _get_resource_type(path: String) -> String:
	if path.get_extension() == "gvint":
		return "Resource"
	return ""


func _get_resource_script_class(path: String) -> String:
	if path.get_extension() == "gvint":
		return "EditorGvintScriptReference"
	return ""


func _handles_type(type: StringName) -> bool:
	return type == "Resource"


func _load(
		path: String, _original_path: String, _use_sub_threads: bool, 
		_cache_mode: int
		) -> Variant:
	var script_metadata := EditorGvintScriptReference.new()
	return script_metadata
