extends Node3D
class_name FirewallEnemy

@onready var sprite: Sprite3D = $Sprite3D

@export var grid_path: NodePath
@export var player_path: NodePath
@export var move_duration := 0.19

enum PatrolAxis { X, Z }
@export var patrol_axis := PatrolAxis.X

@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

var grid: Grid
var player: Player
var grid_pos := Vector2i.ZERO
var _is_busy := false
var stun_turns := 0
var _disabled := false:
	set(value):
		_disabled = value
		sprite.frame = 1 if value else 0

func _ready() -> void:
	add_to_group("firewall_enemies")

	if grid_path:
		grid = get_node(grid_path) as Grid
	if player_path:
		player = get_node(player_path) as Player

	if grid:
		grid_pos = grid.world_to_grid(position)
		position = grid.grid_to_world(grid_pos)
		position.y = 0

	if player:
		player.moved.connect(_on_player_moved)

func _on_player_moved(_player_new_pos: Vector2i) -> void:
	if stun_turns > 0:
		stun_turns -= 1
		if stun_turns == 0:
			sprite.frame = 0
		return

	if _disabled or _is_busy or not player or not grid:
		return

	var player_coord: int
	var my_coord: int
	if patrol_axis == PatrolAxis.X:
		player_coord = player.grid_pos.x
		my_coord = grid_pos.x
	else:
		player_coord = player.grid_pos.y
		my_coord = grid_pos.y

	if player_coord == my_coord:
		return

	var step := 1 if player_coord > my_coord else -1
	var target_grid_pos := grid_pos
	if patrol_axis == PatrolAxis.X:
		target_grid_pos.x += step
	else:
		target_grid_pos.y += step
	
	for barrier in get_tree().get_nodes_in_group("barriers"):
		if barrier.grid_pos == target_grid_pos:
			return
	
	if grid.has_tile_at(target_grid_pos) and target_grid_pos != player.grid_pos:
		move_to(target_grid_pos)

func move_to(new_grid_pos: Vector2i) -> void:
	grid_pos = new_grid_pos
	var target_position := grid.grid_to_world(grid_pos)
	target_position.y = position.y
	
	audio_stream_player_3d.stream = load("res://Audio/Characters/firewall_slide.mp3")
	audio_stream_player_3d.play()

	_is_busy = true
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", target_position, move_duration)
	tween.finished.connect(func(): _is_busy = false)
	

func is_at(check_pos: Vector2i) -> bool:
	return grid_pos == check_pos

func stun(turns: int) -> void:
	stun_turns = turns
	sprite.frame = 1
	
	audio_stream_player_3d.stream = load("res://Audio/Tools/fire_extinguish.mp3")
	audio_stream_player_3d.play()
