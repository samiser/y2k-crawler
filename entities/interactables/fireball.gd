extends Node3D
class_name Fireball

var wall : FirewallEnemy

func _process(delta: float) -> void:
	var dir := (global_position - wall.global_position).normalized()
	while global_position.distance_to(wall.global_position) > 1.0:
		global_position += dir * delta * 20.0
		_impact()
	
func _impact() -> void:
	queue_free()
