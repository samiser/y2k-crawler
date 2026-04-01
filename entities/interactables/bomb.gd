extends Node3D
class_name Bomb

@export var grid_path: NodePath
@onready var explosion_player: AudioStreamPlayer3D = $ExplosionPlayer

var grid: Grid
var grid_pos := Vector2i.ZERO

func _ready() -> void:
	add_to_group("bombs")

	if grid_path:
		grid = get_node(grid_path) as Grid

	if grid:
		grid_pos = grid.world_to_grid(position)
		grid.register_item(grid_pos, self)

func _exit_tree() -> void:
	if grid:
		grid.unregister_item(grid_pos, self)

func is_at(check_pos: Vector2i) -> bool:
	return grid_pos == check_pos

func explode() -> void:
	explosion_player.play()
