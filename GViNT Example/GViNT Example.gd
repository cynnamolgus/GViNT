extends Control


onready var script_runtime = $GvintRuntimeStateful

func _ready():
	$StartButton.show()
	$SideMenu.hide()
	$TextBox.hide()

func _on_StartButton_pressed():
	script_runtime.start("res://Story/start.txt")
	$StartButton.hide()
	$SideMenu.show()
	$TextBox.show()


func _on_GvintRuntimeStateful_script_execution_finished():
	$StartButton.show()
	$SideMenu.hide()
	$TextBox.hide()
