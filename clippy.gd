extends Node3D
class_name ClippyEnemy

signal caught_player

@onready var sprite: Sprite3D = $Sprite3D

@export var grid_path: NodePath
@export var player_path: NodePath
@export var player_spawn: Vector2i
@export var player_spawn_facing: Player.Facing
@export var move_duration := 0.2

var grid: Grid
var player: Player
var grid_pos := Vector2i.ZERO
var spawn_pos := Vector2i.ZERO
var _frame := 2
var _is_moving := false
var _has_seen_player := false
var _current_path: Array[Vector2i] = []

func _ready() -> void:
	if grid_path:
		grid = get_node(grid_path) as Grid
	if player_path:
		player = get_node(player_path) as Player

	if grid:
		grid_pos = grid.world_to_grid(position)
		spawn_pos = grid_pos
		position = grid.grid_to_world(grid_pos)
		position.y = 0

	if player:
		player.moved.connect(_on_player_moved)

func _process(_delta: float) -> void:
	if Engine.get_frames_drawn() % 30 == 0:
		_frame = 3 if _frame == 2 else 2
	sprite.frame = _frame

func _on_player_moved(_player_new_pos: Vector2i) -> void:
	if not grid or not player or _is_moving:
		return

	if not _has_seen_player:
		if grid.has_line_of_sight(grid_pos, player.grid_pos):
			_has_seen_player = true

	if _has_seen_player:
		_update_path_and_move()

func _update_path_and_move() -> void:
	_current_path = grid.get_grid_path(grid_pos, player.grid_pos)

	if _current_path.size() > 1:
		var next_pos: Vector2i = _current_path[1]
		_move_to(next_pos)

func _move_to(new_grid_pos: Vector2i) -> void:
	grid_pos = new_grid_pos
	var target_position := grid.grid_to_world(grid_pos)
	target_position.y = position.y

	_is_moving = true
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", target_position, move_duration)
	tween.finished.connect(_on_move_finished)

func _on_move_finished() -> void:
	_is_moving = false
	if _is_adjacent_to_player():
		_catch_player()

func _is_adjacent_to_player() -> bool:
	var diff := player.grid_pos - grid_pos
	return absi(diff.x) + absi(diff.y) == 1

func _catch_player() -> void:
	caught_player.emit()
	_reset_to_spawn()
	_teleport_player_to_spawn()

func _reset_to_spawn() -> void:
	grid_pos = spawn_pos
	position = grid.grid_to_world(grid_pos)
	position.y = 0
	_has_seen_player = false
	_current_path.clear()

func _teleport_player_to_spawn() -> void:
	player.teleport_to(player_spawn, player_spawn_facing)
