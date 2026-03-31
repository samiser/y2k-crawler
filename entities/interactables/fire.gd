extends Node3D
class_name Fire

@export var grid_path: NodePath

@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var sprite: Sprite3D = $Sprite3D
var _frame : int

var grid: Grid
var grid_pos := Vector2i.ZERO

func _ready() -> void:
	add_to_group("fire")
	
	if grid_path:
		grid = get_node(grid_path) as Grid
	
	if grid:
		grid_pos = grid.world_to_grid(position)
		position = grid.grid_to_world(grid_pos)
		position.y = 0

func extinguish() -> void:
	remove_from_group("fire")
	
	audio_stream_player_3d.stream = load("res://Audio/Tools/fire_extinguish.mp3")
	audio_stream_player_3d.play()
	
	var tween := get_tree().create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 1.2)
	await tween.finished
	
	queue_free()

func _exit_tree() -> void:
	remove_from_group("fire")

func _process(_delta: float) -> void:
	if Engine.get_frames_drawn() % 20 == 0:
		_frame = 4 if _frame == 3 else 3
	sprite.frame = _frame
