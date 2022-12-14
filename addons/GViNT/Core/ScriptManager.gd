tool
extends Node


const DEFAULT_SCRIPT_DIR = "res://Story/"
const DEFAULT_SCRIPT_EXTENSION = ".story"

const SCRIPT_INFO_FILE = "res://addons/GViNT/Config/scripts.json"
const COMPILED_SCRIPTS_DIR = "res://addons/GViNT/Config/ScriptCache/"

const _INSTRUCTION_PREFIX = "Instruction_"


const GvintUtils = preload("res://addons/GViNT/Core/Utils.gd")
const ScriptTemplates = preload("res://addons/GViNT/Core/Translator/Templates/ScriptTemplates.gd")
const Translator = preload("res://addons/GViNT/Core/Translator/Translator.gd")


var translator := Translator.new()
var script_info := {}


func _ready():
	_load_script_info()


func _load_script_info():
	script_info = GvintUtils.load_json_dict(SCRIPT_INFO_FILE)
	assert(script_info != null)
	
	delete_obsolete_script_info()
	_load_context_factories()


func _load_context_factories():
	var context_factory_filename: String
	for script_filename in script_info:
		context_factory_filename = script_info[script_filename]["context_factory_filename"]
		script_info[script_filename]["context_factory"] = load(context_factory_filename)


func save_script_info():
	var saved_data := script_info.duplicate(true)
	for script in saved_data:
		saved_data[script].erase("context_factory")
	
	var indentation := "  "
	var json_string := JSON.print(saved_data, indentation)
	var f = File.new()
	f.open(SCRIPT_INFO_FILE, File.WRITE)
	f.store_string(json_string)


func load_script(source_filename: String) -> GvintContext:
	source_filename = _expand_source_filename(source_filename)
	
	var d := Directory.new()
	var script_exists := d.file_exists(source_filename)
	assert(script_exists, "Script '" + source_filename + "' not found")
	
	if not script_exists:
		return null
	
	var context_factory: GDScript
	if script_needs_compiling(source_filename):
		print("compiling script: " + source_filename)
		context_factory = compile_script(source_filename)
	else:
		print("loading compiled script: " + source_filename)
		context_factory = script_info[source_filename]["context_factory"]
	return context_factory.get_context()


func _expand_source_filename(source_filename):
	if not source_filename.begins_with("res://"):
		source_filename = DEFAULT_SCRIPT_DIR + source_filename
	if not "." in source_filename:
		source_filename += DEFAULT_SCRIPT_EXTENSION
	return source_filename


func script_needs_compiling(script: String):
	var f = File.new()
	
	assert(f.file_exists(script))
	
	if not script in script_info:
		return true
	
	var modify_time: int = f.get_modified_time(script)
	var last_compiled: int = script_info[script]["last_compiled"]
	if modify_time > last_compiled:
		return true
	return false


func delete_obsolete_script_info():
	var d := Directory.new()
	var cached_script_directory: String
	for script_filename in script_info:
		if not d.file_exists(script_filename):
			script_info.erase(script_filename)
			cached_script_directory = COMPILED_SCRIPTS_DIR + script_filename.md5_text()
			GvintUtils.delete_directory(cached_script_directory)
	save_script_info()


func compile_script(script: String):
	var filename_hash := script.md5_text()
	var compiled_script_directory := COMPILED_SCRIPTS_DIR + filename_hash + "/"
	
	script_info[script] = {}
	GvintUtils.delete_directory(compiled_script_directory)
	
	var d := Directory.new()
	d.make_dir(compiled_script_directory)
	
	translator.clear()
	var gdscript_sources: Array = translator.translate_file(script)
	var instruction_files := _save_compiled_instructions(compiled_script_directory, gdscript_sources)
	var context_factory := _create_context_factory(compiled_script_directory, script, instruction_files)
	
	var current_time: int = floor(Time.get_unix_time_from_system())
	script_info[script]["last_compiled"] = current_time
	save_script_info()
	return context_factory


func _save_compiled_instructions(directory: String, gdscript_sources: Array) -> Array:
	var instructions := {}
	var instruction_filename_template := _INSTRUCTION_PREFIX + "%s.gd"
	var instruction_filename: String
	var i: int = 0
	for instruction_gdscript in gdscript_sources:
		instruction_filename = _INSTRUCTION_PREFIX + str(i) + ".gd"
		instructions[instruction_filename] = instruction_gdscript
		i+= 1
	return GvintUtils.save_files(directory, instructions)


func _create_context_factory(directory: String, source_filename: String, instruction_filenames: Array) -> GDScript:
	var context_factory_filename: String = directory + "Loader.gd"
	var context_factory_source: String = _construct_context_factory_script(source_filename, instruction_filenames)
	
	var f := File.new()
	f.open(context_factory_filename, File.WRITE)
	f.store_string(context_factory_source)
	f.close()
	
	var context_factory := load(context_factory_filename) as GDScript
	script_info[source_filename]["context_factory_filename"] = context_factory_filename
	script_info[source_filename]["context_factory"] = context_factory
	return context_factory


func _construct_context_factory_script(source_filename, instruction_files):
	var instruction_preloads := ""
	var instruction_list := "[\n"
	var instruction_identifier: String
	var i: int = 0
	for instruction_filename in instruction_files:
		instruction_identifier = "	" + _INSTRUCTION_PREFIX + str(i)
		instruction_list += instruction_identifier + ",\n"
		instruction_preloads += ScriptTemplates.LOADER_INSTRUCTION.format({
			"instruction_index": i,
			"instruction_filename": instruction_filename
		}) + "\n"
		i += 1
	instruction_list += "]"
	return ScriptTemplates.LOADER.format({
		"instruction_preloads": instruction_preloads,
		"instruction_list": instruction_list,
		"source_filename": source_filename,
	})

