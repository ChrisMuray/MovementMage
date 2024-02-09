extends Area3D
class_name IceBlock

func _on_timer_timeout() -> void:
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		body.ice_num += 1

func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		body.ice_num -= 1
