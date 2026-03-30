extends Node3D

@export var grid_path: NodePath
@export var player_path: NodePath
@export var dialogue: Array[String] = []

var grid: Grid
var player: Player
var grid_pos := Vector2i.ZERO
var _dialogue_index := -1

@onready var label_3d: Label3D = $Label3D

func _ready() -> void:
	add_to_group("barriers")
	add_to_group("msn")
	if grid_path:
		grid = get_node(grid_path) as Grid
	if player_path:
		player = get_node(player_path) as Player
	if grid:
		grid_pos = grid.world_to_grid(position)
	if player:
		player.moved.connect(_on_player_moved)
	label_3d.text = ""

func _on_player_moved(_new_pos: Vector2i) -> void:
	if _dialogue_index < 0:
		return
	var facing_pos: Vector2i = player.grid_pos + Player.FACING_TO_DIRECTION[player.facing]
	if facing_pos != grid_pos:
		_reset()

func is_at(check_pos: Vector2i) -> bool:
	return grid_pos == check_pos

func interact() -> void:
	_dialogue_index += 1
	if _dialogue_index >= dialogue.size():
		_reset()
	else:
		label_3d.text = dialogue[_dialogue_index]

func _reset() -> void:
	_dialogue_index = -1
	label_3d.text = ""
