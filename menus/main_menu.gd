extends Control

@onready var play_button: Button = $CenterContainer/VBoxContainer/PlayButton
const INTRO = preload("res://menus/intro.tscn")

func _ready() -> void:
	play_button.pressed.connect(func() -> void: get_tree().change_scene_to_packed(INTRO))
	play_button.grab_focus()
	Input.set_custom_mouse_cursor(load("res://sprites/ui/cursor_default.bmp"))
	Input.set_custom_mouse_cursor(load("res://sprites/ui/cursor_hover.bmp"), Input.CURSOR_POINTING_HAND)
