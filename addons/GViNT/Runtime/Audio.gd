extends Node



var sfx_history := []
var bgm_track: GvintVariable

onready var runtime: GvintRuntime = get_parent()


func _ready():
	init_bgm()


func init_bgm():
	bgm_track = runtime.init_runtime_var("bgm")
	bgm_track.connect("value_changed", self, "on_bgm_changed")


func play_sfx(sound):
	pass

func undo_play_sfx():
	pass

func on_bgm_changed(new_value):
	pass

