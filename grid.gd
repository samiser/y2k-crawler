@tool
extends Node3D
class_name Grid

const TILE_SIZE := 2.0

var tiles: Dictionary = {}
var _last_positions: Dictionary = {}

func _ready() -> void:
	refresh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_CHILD_ORDER_CHANGED:
		call_deferred("refresh")

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_check_for_moved_tiles()

func _check_for_moved_tiles() -> void:
	for child in get_children():
		if child is Tile:
			var current_pos := world_to_grid(child.position)
			if _last_positions.get(child) != current_pos:
				_last_positions[child] = current_pos
				refresh()
				return

func collect_tiles() -> void:
	tiles.clear()
	_last_positions.clear()
	for child in get_children():
		if child is Tile:
			var grid_pos := world_to_grid(child.position)
			tiles[grid_pos] = child
			_last_positions[child] = grid_pos

func world_to_grid(world_pos: Vector3) -> Vector2i:
	return Vector2i(
		roundi(world_pos.x / TILE_SIZE),
		roundi(world_pos.z / TILE_SIZE)
	)

func grid_to_world(grid_pos: Vector2i) -> Vector3:
	return Vector3(grid_pos.x * TILE_SIZE, 0, grid_pos.y * TILE_SIZE)

func update_all_walls() -> void:
	for grid_pos in tiles:
		update_tile_walls(grid_pos)

func update_tile_walls(grid_pos: Vector2i) -> void:
	var tile: Tile = tiles[grid_pos]
	tile.set_wall_visible("north", not has_tile_at(grid_pos + Vector2i(0, 1)))
	tile.set_wall_visible("south", not has_tile_at(grid_pos + Vector2i(0, -1)))
	tile.set_wall_visible("east", not has_tile_at(grid_pos + Vector2i(-1, 0)))
	tile.set_wall_visible("west", not has_tile_at(grid_pos + Vector2i(1, 0)))

func has_tile_at(grid_pos: Vector2i) -> bool:
	return tiles.has(grid_pos)

func refresh() -> void:
	collect_tiles()
	update_all_walls()
