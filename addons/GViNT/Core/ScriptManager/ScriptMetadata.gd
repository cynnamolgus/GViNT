extends Reference

const GvintConfig = preload("res://addons/GViNT/Core/Config.gd")

class CompilationData:
	var compiled_filename: String
	var timestamp: int

var source_filename: String
var compiled_for_configs := {}

var context_loader

func to_json_object() -> Dictionary:
	var data = {}
	data["source_filename"] = source_filename
	data["compiled_for_configs"] = {}
	for config_id in compiled_for_configs:
		var compilation_metadata = compiled_for_configs[config_id]
		var json_entry = {}
		json_entry["compiled_filename"] = compilation_metadata.compiled_filename
		json_entry["timestamp"] = compilation_metadata.timestamp
		data["compiled_for_configs"][config_id] = json_entry
	return data

func load_from_json_object(data: Dictionary):
	compiled_for_configs.clear()
	source_filename = data.source_filename
	for config_id in data.compiled_for_configs:
		var config_data = data.compiled_for_configs[config_id]
		var metadata = CompilationData.new()
		metadata.compiled_filename = config_data["compiled_filename"]
		metadata.timestamp = config_data["timestamp"]
		compiled_for_configs[config_id] = metadata


func get_context_loader(config: GvintConfig):
	assert(is_compiled_for_config(config))
	var loader = load(compiled_for_configs[config.id].compiled_filename)
	return loader


func is_compiled_for_config(config: GvintConfig):
	return config.id in compiled_for_configs

