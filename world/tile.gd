@tool
extends Node3D
class_name Tile

@export var north_frame := 0:
	set(value):
		north_frame = _set_frame(north_wall, value)
@export var south_frame := 0:
	set(value):
		south_frame = _set_frame(south_wall, value)
@export var east_frame := 0:
	set(value):
		east_frame = _set_frame(east_wall, value)
@export var west_frame := 0:
	set(value):
		west_frame = _set_frame(west_wall, value)
@export var floor_frame := 4:
	set(value):
		floor_frame = _set_frame(floor, value)
@export var ceiling_frame := 2:
	set(value):
		ceiling_frame = _set_frame(ceiling, value)

@export var show_roof: bool = false:
	set(value):
		show_roof = value
		if ceiling:
			ceiling.visible = show_roof

@onready var north_wall: Sprite3D = $North
@onready var south_wall: Sprite3D = $South
@onready var east_wall: Sprite3D = $East
@onready var west_wall: Sprite3D = $West
@onready var floor: Sprite3D = $Floor
@onready var ceiling: Sprite3D = $Ceiling

func _set_frame(sprite: Sprite3D, value: int) -> int:
	if sprite:
		sprite.frame = value
	return value

func set_wall_visible(direction: String, visible: bool) -> void:
	match direction:
		"north":
			north_wall.visible = visible
		"south":
			south_wall.visible = visible
		"east":
			east_wall.visible = visible
		"west":
			west_wall.visible = visible

func _ready() -> void:
	_set_frame(north_wall, north_frame)
	_set_frame(south_wall, south_frame)
	_set_frame(east_wall, east_frame)
	_set_frame(west_wall, west_frame)
	_set_frame(floor, floor_frame)
	_set_frame(ceiling, ceiling_frame)
	if Engine.is_editor_hint():
		ceiling.visible = false
