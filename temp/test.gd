tool
extends EditorScript



const Translator = preload("res://GViNT/Translator/Translator.gd")

var translator := Translator.new()


func _run():
	var gdscript = translator.translate_file("res://lorem.txt")
	var f = File.new()
	var i = 0
	for source in gdscript:
		i += 1
		f.open("res://temp/" + str(i) + ".gd", File.WRITE)
		f.store_string(source)
		f.close()



