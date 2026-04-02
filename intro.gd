extends Control

@onready var intro_sprites: Sprite2D = $VBoxContainer/CenterContainer/Control/IntroSprites

@onready var _1: RichTextLabel = %"1"
@onready var _2: RichTextLabel = %"2"
@onready var _3: RichTextLabel = %"3"

@onready var music_player: AudioStreamPlayer = %MusicPlayer
@onready var music_stream: AudioStreamOggVorbis = music_player.stream
@onready var fade_out: ColorRect = %FadeOut

var current_step := 0
var text_tween_duration := 5.0

func _ready() -> void:
	intro_sprites.frame = 0
	_1.visible_ratio = 0
	_tween_text(_1)
	get_tree().create_timer(60 / music_stream.bpm * 16).timeout.connect(_advance_scene)

func _tween_text(label: RichTextLabel) -> void:
	var tween := create_tween()
	tween.tween_property(label, "visible_ratio", 1.0, text_tween_duration)

func _advance_scene() -> void:
	current_step += 1
	match current_step:
		1:
			intro_sprites.frame = 1
			_1.visible = false
			_2.visible = true
			_2.visible_ratio = 0
			_tween_text(_2)
			get_tree().create_timer(60 / music_stream.bpm * 16).timeout.connect(_advance_scene)
		2:
			intro_sprites.frame = 2
			_2.visible = false
			_3.visible = true
			_3.visible_ratio = 0
			_tween_text(_3)
			get_tree().create_timer(60 / music_stream.bpm * 16).timeout.connect(_advance_scene)
		3:
			var time_left := music_player.stream.get_length() - music_player.get_playback_position()
			var tween := create_tween()
			tween.tween_property(fade_out, "modulate:a", 1.0, time_left)
			tween.finished.connect(func():
				music_player.stop()
				get_tree().change_scene_to_file("res://main.tscn")
			)
