extends Node3D
class_name Barrier

signal interacted

@export var grid_path: NodePath
@export var player_path: NodePath

var grid: Grid
var player: Player
var grid_pos := Vector2i.ZERO

func _ready() -> void:
	add_to_group("barriers")

	if grid_path:
		grid = get_node(grid_path) as Grid
	if player_path:
		player = get_node(player_path) as Player

	if grid:
		grid_pos = grid.world_to_grid(position)

func _on_area_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if not player:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_player_adjacent():
			interacted.emit()
			queue_free()

func _is_player_adjacent() -> bool:
	var diff := player.grid_pos - grid_pos
	return absi(diff.x) + absi(diff.y) == 1

func is_at(check_pos: Vector2i) -> bool:
	return grid_pos == check_pos
