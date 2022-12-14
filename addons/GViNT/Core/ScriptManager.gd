tool
extends Node


const DEFAULT_SCRIPT_DIR = "res://Story/"
const SCRIPT_INFO_FILE = "res://addons/GViNT/Config/scripts.json"
const COMPILED_SCRIPTS_DIR = "res://addons/GViNT/Config/ScriptCache/"
const INSTRUCTION_PREFIX = "Instruction_"

const Templates = preload("res://addons/GViNT/Core/Translator/Templates/Templates.gd")
const Translator = preload("res://addons/GViNT/Core/Translator/Translator.gd")


var translator := Translator.new()
var script_info := {}


func _ready():
	load_script_info()

func read_file(file: String) -> String:
	var f := File.new()
	var error = f.open(file, File.READ)
	assert(not error)
	if error:
		push_error(str(error))
	
	var data: String
	if f.is_open():
		data = f.get_as_text()
		f.close()
	
	return data

func load_script_info():
	var json_string := read_file(SCRIPT_INFO_FILE)
	var parse_result := JSON.parse(json_string)
	assert(not parse_result.error)
	if parse_result.error:
		push_error(parse_result.error_string)
	else:
		script_info = (parse_result.result) as Dictionary
		assert(script_info != null)
	
	var loader_filename: String
	delete_removed_scripts()
	save_script_info()
	for script_filename in script_info:
		loader_filename = script_info[script_filename]["loader_filename"]
		script_info[script_filename]["loader"] = load(loader_filename)


func load_script(source_filename: String) -> GvintContext:
	if not source_filename.begins_with("res://"):
		source_filename = DEFAULT_SCRIPT_DIR + source_filename
	var d := Directory.new()
	assert(d.file_exists(source_filename), "Script '" + source_filename + "' not found")
	var loader: GDScript
	if script_needs_compiling(source_filename):
		print("compiling script: " + source_filename)
		loader = compile_script(source_filename)
	else:
		print("loading compiled script: " + source_filename)
		loader = script_info[source_filename]["loader"]
	return loader.get_context()


func script_needs_compiling(script: String):
	var f = File.new()
	if not f.file_exists(script):
		return true
	if not script in script_info:
		return true
	var modify_time: int = f.get_modified_time(script)
	var last_compiled: int = script_info[script]["last_compiled"]
	if modify_time > last_compiled:
		return true
	return false


func delete_removed_scripts():
	var d := Directory.new()
	for script_filename in script_info:
		if not d.file_exists(script_filename):
			script_info.erase(script_filename)
			delete_compiled_script(script_filename.md5_text())


func delete_compiled_script(filename_hash: String):
	var d := Directory.new()
	d.open(COMPILED_SCRIPTS_DIR)
	if d.dir_exists(filename_hash):
		OS.move_to_trash(ProjectSettings.globalize_path(COMPILED_SCRIPTS_DIR + filename_hash))


func compile_script(script: String):
	script_info[script] = {}
	var filename_hash := script.md5_text()
	delete_compiled_script(filename_hash)
	var d := Directory.new()
	d.open(COMPILED_SCRIPTS_DIR)
	d.make_dir(filename_hash)
	
	translator.clear()
	var gdscript_sources: Array = translator.translate_file(script)
	
	var compiled_script_dir := COMPILED_SCRIPTS_DIR + filename_hash + "/"
	var instruction_files := save_sources(compiled_script_dir, gdscript_sources)
	var loader := create_loader(compiled_script_dir, script, instruction_files)
	
	var current_time: int = floor(Time.get_unix_time_from_system())
	script_info[script]["last_compiled"] = current_time
	script_info[script]["loader"] = loader
	save_script_info()
	return loader

func save_sources(dir: String, sources: Array) -> Array:
	var files: int = len(sources)
	var saved_files := []
	dir += INSTRUCTION_PREFIX
	
	var saved_filename: String
	var i = 0
	var f := File.new()
	for source in sources:
		saved_filename = dir + str(i) + ".gd"
		f.open(saved_filename, File.WRITE)
		f.store_string(source)
		f.close()
		saved_files.append(saved_filename)
		i+= 1 
	return saved_files

func create_loader(dir: String, source_filename: String, instruction_files: Array) -> GDScript:
	var loader_filename: String = dir + "Loader.gd"
	var instruction_preloads := ""
	var instruction_list := "[\n"
	var instruction_identifier: String
	var i: int = 0
	for instruction_filename in instruction_files:
		instruction_identifier = "	" + INSTRUCTION_PREFIX + str(i)
		instruction_list += instruction_identifier + ",\n"
		instruction_preloads += Templates.LOADER_INSTRUCTION.format({
			"instruction_index": i,
			"instruction_filename": instruction_filename
		}) + "\n"
		i += 1
	instruction_list += "]"
	
	var f := File.new()
	f.open(loader_filename, File.WRITE)
	f.store_string(Templates.LOADER.format({
		"instruction_preloads": instruction_preloads,
		"instruction_list": instruction_list,
		"source_filename": source_filename,
	}))
	f.close()
	
	script_info[source_filename]["loader_filename"] = loader_filename
	
	return load(loader_filename) as GDScript


func save_script_info():
	var json_string := JSON.print(script_info)
	var f = File.new()
	f.open(SCRIPT_INFO_FILE, File.WRITE)
	f.store_string(json_string)


