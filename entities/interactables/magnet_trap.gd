extends Node3D
class_name MagnetTrap

var grid_path: NodePath
var grid: Grid
var grid_pos := Vector2i.ZERO
var player: Player
var life : int = 6

@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

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

	if life == 0:
		_die()
	else:
		_zap()

func _zap() -> void:
	var zapped : bool = false
	
	for coin in get_tree().get_nodes_in_group("coins"):
		if (coin.global_position.distance_to(global_position) < 6.0):
			if grid.has_line_of_sight(grid_pos, coin.grid_pos):
				zapped = true
				
				grid.unregister_item(coin.grid_pos, coin)
				
				coin.grid_pos = grid_pos
				
				var ran_offset_magnitude : float = 0.6
				var pos_ran_offset : Vector3 = Vector3(randf_range(-ran_offset_magnitude, ran_offset_magnitude), 0, randf_range(-ran_offset_magnitude, ran_offset_magnitude))
				grid.register_item(grid_pos, coin)
				
				var tween := get_tree().create_tween()
				tween.tween_property(coin, "position", grid.grid_to_world(grid_pos) + pos_ran_offset, 0.4)
	
	for clippy in get_tree().get_nodes_in_group("clippy_enemies"):
		if (clippy.global_position.distance_to(global_position) < 3.0):
			zapped = true
			clippy.zapped()
	
	var tween := get_tree().create_tween()
	tween.tween_property(sprite_3d, "position:y", 1.2, 0.5)
	tween.tween_property(sprite_3d, "position:y", 0.5, 0.5)
	
	if zapped:
		audio_stream_player_3d.play()

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
