extends Area3D
class_name IceBlock

func _on_timer_timeout() -> void:
	queue_free()

@onready var player = get_parent()

func _on_body_entered(body: Node3D) -> void:
	if body == player:
		player.ice_num += 1

func _on_body_exited(body: Node3D) -> void:
	if body == player:
		player.ice_num -= 1
