extends Node3D
class_name Fireball

var wall : FirewallEnemy

func _process(delta: float) -> void:
	var dir := (wall.global_position - global_position).normalized()
	if global_position.distance_to(wall.global_position) > 1.0:
		global_position += dir * delta * 20.0
	else:
		_impact()
	
func _impact() -> void:
	queue_free()
