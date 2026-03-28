@tool
extends Node3D
class_name Tile

@onready var north_wall: Sprite3D = $North
@onready var south_wall: Sprite3D = $South
@onready var east_wall: Sprite3D = $East
@onready var west_wall: Sprite3D = $West

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
