extends Node3D
class_name Pit

@export var grid_path: NodePath

var grid: Grid
var grid_pos := Vector2i.ZERO

func _ready() -> void:
	add_to_group("barriers")

	if grid_path:
		grid = get_node(grid_path) as Grid

	if grid:
		grid_pos = grid.world_to_grid(position)
		position = grid.grid_to_world(grid_pos)
		position.y = 0

func is_at(check_pos: Vector2i) -> bool:
	return grid_pos == check_pos
