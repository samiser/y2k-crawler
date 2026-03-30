extends Node3D
class_name Coin

@export var grid_path: NodePath
@onready var sprite_3d: Sprite3D = $Sprite3D

var grid: Grid
var grid_pos := Vector2i.ZERO

func _ready() -> void:
	add_to_group("coins")

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
	
func _process(delta: float) -> void:
	var height_offset : float = sin(Time.get_ticks_msec() * 0.1 * delta) * 0.1
	sprite_3d.position.y = 0.5 + height_offset
