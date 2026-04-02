extends Control

@onready var intro_sprites: Sprite2D = $VBoxContainer/CenterContainer/Control/IntroSprites

@onready var _1: RichTextLabel = %"1"
@onready var _2: RichTextLabel = %"2"
@onready var _3: RichTextLabel = %"3"

var current_step := 0

func _ready() -> void:
	intro_sprites.frame = 0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("use"):
		current_step += 1
		match current_step:
			1:
				intro_sprites.frame = 1
				_1.visible = false
				_2.visible = true
			2:
				intro_sprites.frame = 2
				_2.visible = false
				_3.visible = true
			3:
				get_tree().change_scene_to_file("res://main.tscn")
