extends Node3D
class_name ClippyEnemy

@onready var sprite: Sprite3D = $Sprite3D

@export var grid_path: NodePath
@export var player_path: NodePath

var grid: Grid
var player: Player
var grid_pos := Vector2i.ZERO
var frame = 2

func _ready() -> void:
	if grid_path:
		grid = get_node(grid_path) as Grid
	if player_path:
		player = get_node(player_path) as Player

	if grid:
		grid_pos = grid.world_to_grid(position)
		position = grid.grid_to_world(grid_pos)
		position.y = 0

func _process(delta: float) -> void:
	if Engine.get_frames_drawn() % 30 == 0:
		if frame == 2:
			frame = 3
		else:
			frame = 2
	sprite.frame = frame
