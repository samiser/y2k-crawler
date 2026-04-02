extends Node3D
class_name Fireball

var target : Node3D
var player : Player

var impacted : bool = false

func _process(delta: float) -> void:
	if impacted or target == null:
		return
	
	var dir := (target.global_position - global_position).normalized()
	var target_dist := global_position.distance_to(target.global_position)
	var player_dist := global_position.distance_to(player.global_position)
	
	if target_dist > 1.0 and player_dist > 1.0:
		global_position += dir * delta * 20.0
	else:
		_impact(player_dist)
	
func _impact(player_dist : float) -> void:
	impacted = true

	if player_dist < 1.0:
		player.fireball_damage()
	queue_free()
