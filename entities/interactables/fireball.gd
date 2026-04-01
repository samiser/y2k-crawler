extends Node3D
class_name Fireball

var direction : Vector2i
var life : float = 3.0

func _process(delta: float) -> void:
	life -= delta
	
	if life <= 0.0:
		queue_free()
		return
	
	global_position += Vector3(direction.x, 0, direction.y) * delta * 20.0
