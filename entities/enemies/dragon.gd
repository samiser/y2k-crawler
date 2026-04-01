extends Node3D
class_name DragonEnemy

@export var grid_path: NodePath
@export var fire_dir := Vector2i.RIGHT
@export var player_path: NodePath

@onready var sprite: Sprite3D = $Sprite3D
@onready var fireball := preload("res://entities/interactables/fireball.tscn")

var grid: Grid
var player: Player
var grid_pos := Vector2i.ZERO

func _ready() -> void:
	add_to_group("barriers")

	if grid_path:
		grid = get_node(grid_path) as Grid

	if grid:
		grid_pos = grid.world_to_grid(position)
		position = grid.grid_to_world(grid_pos)
		position.y = 0
	
	if player_path:
		player = get_node(player_path) as Player

	if player:
		player.moved.connect(_on_player_moved)

func _on_player_moved(_player_new_pos: Vector2i) -> void:
	if not grid or not player:
		return
	
	_fireball() 

func _fireball() -> void:
	sprite.frame = 6
	
	var fb := fireball.instantiate()
	fb.direction = fire_dir
	fb.global_position = global_position
	get_tree().root.add_child(fb)
	
	var timer := get_tree().create_timer(1.0)
	await timer.timeout
	
	sprite.frame = 7

func is_at(check_pos: Vector2i) -> bool:
	return grid_pos == check_pos
