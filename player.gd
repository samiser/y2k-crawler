extends Node3D
class_name Player

signal moved(new_grid_pos: Vector2i)

@export var grid_path: NodePath
@export var move_duration := 0.25
@export var turn_duration := 0.25

enum Facing { NORTH, EAST, SOUTH, WEST }

var grid: Grid
var grid_pos := Vector2i.ZERO
@export var facing := Facing.NORTH
var _is_busy := false

const FACING_TO_DIRECTION := {
	Facing.NORTH: Vector2i(0, 1),
	Facing.EAST: Vector2i(-1, 0),
	Facing.SOUTH: Vector2i(0, -1),
	Facing.WEST: Vector2i(1, 0),
}

const FACING_TO_ANGLE := {
	Facing.NORTH: PI,
	Facing.EAST: PI / 2,
	Facing.SOUTH: 0.0,
	Facing.WEST: -PI / 2,
}

func _ready() -> void:
	if grid_path:
		grid = get_node(grid_path) as Grid
	if grid:
		grid_pos = grid.world_to_grid(position)
		position = grid.grid_to_world(grid_pos)
	rotation.y = FACING_TO_ANGLE[facing]

func _process(_delta: float) -> void:
	if not _is_busy:
		handle_input()

func handle_input() -> void:
	if Input.is_action_pressed("forward"):
		try_move(FACING_TO_DIRECTION[facing])
	elif Input.is_action_pressed("back"):
		try_move(-FACING_TO_DIRECTION[facing])
	elif Input.is_action_pressed("left"):
		try_move(FACING_TO_DIRECTION[wrapi(facing - 1, 0, 4)])
	elif Input.is_action_pressed("right"):
		try_move(FACING_TO_DIRECTION[wrapi(facing + 1, 0, 4)])
	elif Input.is_action_pressed("turn_left"):
		turn(-1)
	elif Input.is_action_pressed("turn_right"):
		turn(1)

func try_move(direction: Vector2i) -> void:
	if not grid:
		return

	var new_grid_pos := grid_pos + direction

	if not grid.has_tile_at(new_grid_pos):
		return

	if is_blocked_by_firewall(new_grid_pos):
		return

	grid_pos = new_grid_pos
	var target_position := grid.grid_to_world(grid_pos)
	target_position.y = position.y

	_is_busy = true
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", target_position, move_duration)
	tween.finished.connect(func(): _is_busy = false)

	moved.emit(grid_pos)

func is_blocked_by_firewall(check_pos: Vector2i) -> bool:
	for enemy in get_tree().get_nodes_in_group("firewall_enemies"):
		if enemy.is_at(check_pos):
			return true
	return false

func turn(direction: int) -> void:
	facing = wrapi(facing + direction, 0, 4) as Facing
	var target_angle: float = FACING_TO_ANGLE[facing]

	_is_busy = true
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_method(_set_rotation_y, rotation.y, _shortest_angle(rotation.y, target_angle), turn_duration)
	tween.finished.connect(func(): _is_busy = false)

func _set_rotation_y(value: float) -> void:
	rotation.y = value

func _shortest_angle(from: float, to: float) -> float:
	var diff := wrapf(to - from, -PI, PI)
	return from + diff
