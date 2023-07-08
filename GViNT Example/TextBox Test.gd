extends Control


onready var script_runtime = $GvintRuntimeStateful

func _ready():
	$StartButton.show()
	$SideMenu.hide()
	$TextBox.hide()

func _on_StartButton_pressed():
	script_runtime.start("start")
	$StartButton.hide()
	$SideMenu.show()
	$TextBox.show()
