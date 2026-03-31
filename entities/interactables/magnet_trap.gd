extends Node3D
class_name MagnetTrap

var grid_path: NodePath
var grid: Grid
var grid_pos := Vector2i.ZERO
var player: Player
var life : int = 4
@onready var sprite_3d: Sprite3D = $Sprite3D

func _ready() -> void:
	add_to_group("magnets")

	if grid_path:
		grid = get_node(grid_path) as Grid

	if grid:
		grid_pos = grid.world_to_grid(position)
		grid.register_item(grid_pos, self)

	if player:
		player.moved.connect(_on_player_moved)

func _on_player_moved(_player_new_pos: Vector2i) -> void:
	life -= 1
	print("shit moved bruh")
	if life == 0:
		_die()

func _die():
	queue_free()

func _exit_tree() -> void:
	remove_from_group("magnets")
	if grid:
		grid.unregister_item(grid_pos, self)

func is_at(check_pos: Vector2i) -> bool:
	return grid_pos == check_pos

func _process(delta: float) -> void:
	var height_offset : float = sin(Time.get_ticks_msec() * 0.1 * delta) * 0.1
	sprite_3d.position.y = 0.5 + height_offset
