@tool
extends Node3D
class_name Grid

const TILE_SIZE := 2.0

var tiles: Dictionary = {}
var _last_positions: Dictionary = {}
var items: Dictionary = {}
var astar: AStarGrid2D

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
	_rebuild_astar()

func _rebuild_astar() -> void:
	if tiles.is_empty():
		return

	var min_pos := Vector2i(999999, 999999)
	var max_pos := Vector2i(-999999, -999999)
	for pos in tiles:
		min_pos.x = mini(min_pos.x, pos.x)
		min_pos.y = mini(min_pos.y, pos.y)
		max_pos.x = maxi(max_pos.x, pos.x)
		max_pos.y = maxi(max_pos.y, pos.y)

	astar = AStarGrid2D.new()
	astar.region = Rect2i(min_pos, max_pos - min_pos + Vector2i.ONE)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.update()

	for x in range(min_pos.x, max_pos.x + 1):
		for y in range(min_pos.y, max_pos.y + 1):
			var pos := Vector2i(x, y)
			if not has_tile_at(pos):
				astar.set_point_solid(pos, true)

func get_grid_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	if not astar or not has_tile_at(from) or not has_tile_at(to):
		return []
	return astar.get_id_path(from, to)

func has_line_of_sight(from: Vector2i, to: Vector2i) -> bool:
	var diff := to - from
	var steps := maxi(absi(diff.x), absi(diff.y))
	if steps == 0:
		return true

	for i in range(1, steps + 1):
		var t := float(i) / float(steps)
		var check_pos := Vector2i(
			roundi(from.x + diff.x * t),
			roundi(from.y + diff.y * t)
		)
		if not has_tile_at(check_pos):
			return false
	return true

func register_item(pos: Vector2i, item: Node) -> void:
	if not items.has(pos):
		items[pos] = []
	items[pos].append(item)

func unregister_item(pos: Vector2i, item: Node) -> void:
	if items.has(pos):
		items[pos].erase(item)
		if items[pos].is_empty():
			items.erase(pos)

func get_items_at(pos: Vector2i) -> Array:
	if items.has(pos):
		return items[pos].duplicate()
	return []
