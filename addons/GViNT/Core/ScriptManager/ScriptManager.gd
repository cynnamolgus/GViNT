tool
extends Node


const GvintUtils = preload("res://addons/GViNT/Core/Utils.gd")
const GvintConfig = preload("res://addons/GViNT/Core/Config.gd")
const ScriptMetadata = preload("res://addons/GViNT/Core/ScriptManager/ScriptMetadata.gd")
const Translator = preload("res://addons/GViNT/Core/Translator/Translator.gd")

const CONFIGS_FILENAME = "res://addons/GViNT/configs.json"

const CACHE_DIRECTORY = "res://addons/GViNT/ScriptCache/"
const CACHE_INFO_FILE = "res://addons/GViNT/ScriptCache/scripts.json"

var translator := Translator.new()

var compiled_scripts := {}
var configs := {}


func _ready():
	_load_configs()
	_load_script_compilation_metadata()
	_delete_obsolete_data()


func _load_configs():
	var json_array = GvintUtils.load_json_array(CONFIGS_FILENAME)
	for config_data in json_array:
		var config = GvintConfig.new()
		config.load_from_json_object(config_data)
		configs[config_data.id] = config


func load_script(source_filename: String, config_id: String = "cutscene"):
	
	var config: GvintConfig = configs[config_id]
	if _script_needs_compiling(source_filename, config):
		_compile_script(source_filename, config)
	else:
		print("Loading '" + source_filename + "' compiled for config '" + config_id + "'")
	
	var metadata: ScriptMetadata = compiled_scripts[source_filename]
	
	assert(metadata.is_compiled_for_config(config)) 
	var loader = metadata.get_context_loader(config)
	return loader


func _script_needs_compiling(script_filename: String, config: GvintConfig):
	var config_id = config.id
	var f = File.new()
	
	assert(f.file_exists(script_filename))
	
	if not script_filename in compiled_scripts:
		return true
	
	var metadata: ScriptMetadata = compiled_scripts[script_filename]
	
	if not config.id in metadata.compiled_for_configs:
		return true
	
	var modify_time: int = f.get_modified_time(script_filename)
	var last_compiled = metadata.compiled_for_configs[config.id].timestamp
	if modify_time > last_compiled:
		return true


func _compile_script(source_filename: String, config: GvintConfig):
	print("Compiling '" + source_filename + "' for config '" + config.id + "'")
	var d := Directory.new()
	if not d.dir_exists(CACHE_DIRECTORY + config.id):
		d.make_dir(CACHE_DIRECTORY + config.id)
	
	var compiled_filename = (
		CACHE_DIRECTORY + config.id + "/" 
		+ source_filename.md5_text() + ".gd"
	)
	
	var loader_gdscript = translator.translate_file(source_filename, config)
	GvintUtils.save_file(compiled_filename, loader_gdscript)
	
	var current_time: int = floor(Time.get_unix_time_from_system())
	
	var compilation_data = ScriptMetadata.CompilationData.new()
	compilation_data.compiled_filename = compiled_filename
	compilation_data.timestamp = current_time
	
	var metadata: ScriptMetadata
	if source_filename in compiled_scripts:
		metadata = compiled_scripts[source_filename]
	else:
		metadata = ScriptMetadata.new()
		metadata.source_filename = source_filename
		compiled_scripts[source_filename] = metadata
	
	metadata.compiled_for_configs[config.id] = compilation_data
	_save_script_compilation_metadata()


func clear_cache():
	var d := Directory.new()
	d.open(CACHE_DIRECTORY)
	d.list_dir_begin(true)
	var config_directory = d.get_next()
	while config_directory:
		if config_directory == "scripts.json":
			config_directory = d.get_next()
			continue
		GvintUtils.delete_file_or_directory(CACHE_DIRECTORY + config_directory)
		config_directory = d.get_next()
	compiled_scripts.clear()
	_save_script_compilation_metadata()


func _delete_obsolete_data():
	var d := Directory.new()
	var f := File.new()
	for script_filename in compiled_scripts:
		if not f.file_exists(script_filename):
			_delete_compiled_script(script_filename)
	_save_script_compilation_metadata()


func _delete_compiled_script(script_filename: String):
	assert(script_filename in compiled_scripts)
	var metadata: ScriptMetadata = compiled_scripts[script_filename]
	compiled_scripts.erase(script_filename)
	
	for config_id in metadata.compiled_for_configs:
		var compiled_filename = CACHE_DIRECTORY + config_id + "/" + script_filename.md5_text() + ".gd"
		GvintUtils.delete_file_or_directory(compiled_filename)


func _load_script_compilation_metadata():
	var json_dict = GvintUtils.load_json_dict(CACHE_INFO_FILE)
	for script_filename in json_dict:
		var metadata = ScriptMetadata.new()
		metadata.load_from_json_object(json_dict[script_filename])
		compiled_scripts[script_filename] = metadata

func _save_script_compilation_metadata():
	var saved_data = {}
	for script_filename in compiled_scripts:
		saved_data[script_filename] = compiled_scripts[script_filename].to_json_object()
	
	var indentation := "  "
	var json_string := JSON.print(saved_data, indentation)
	GvintUtils.save_file(CACHE_INFO_FILE, json_string)
