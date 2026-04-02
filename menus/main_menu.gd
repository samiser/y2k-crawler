extends Control

@onready var play_button: Button = $CenterContainer/VBoxContainer/PlayButton
const MAIN = preload("uid://up8x05j0vexy")
const INTRO = preload("uid://up7g4gu006mi")

func _ready() -> void:
	play_button.pressed.connect(func() -> void: get_tree().change_scene_to_packed(INTRO))
