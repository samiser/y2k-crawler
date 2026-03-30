extends Node3D
class_name Terminal

@export var grid_path: NodePath

var grid: Grid
var grid_pos := Vector2i.ZERO

func _ready() -> void:
	add_to_group("terminals")
	if grid_path:
		grid = get_node(grid_path) as Grid
	if grid:
		grid_pos = grid.world_to_grid(position)

func is_at(check_pos: Vector2i) -> bool:
	return grid_pos == check_pos
