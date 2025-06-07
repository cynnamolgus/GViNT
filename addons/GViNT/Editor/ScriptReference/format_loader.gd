@tool
class_name GvintScriptReferenceFormatLoader extends ResourceFormatLoader
## Custom ResourceFormatLoader.
##
## ResourceFormatLoader used to register .gvint files in the editor filesystem.

func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["gvint"])


func _get_resource_type(path: String) -> String:
	if path.get_extension() == "gvint":
		return "Resource"
	return ""


func _get_resource_script_class(_path: String) -> String:
	return ""


func _handles_type(type: StringName) -> bool:
	return type == "Resource"


func _load(
		_path: String, _original_path: String, _use_sub_threads: bool, 
		_cache_mode: int
		) -> Variant:
	var script_metadata := Gvint.ScriptReference.new()
	return script_metadata
