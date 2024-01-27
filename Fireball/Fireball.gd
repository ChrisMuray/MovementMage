extends Area3D

@export var speed := 100.0
var direction: Vector3

func _on_area_entered(_body: Node3D) -> void:
	print("fireball hit")
	queue_free()

func _physics_process(delta: float) -> void:
	position += speed * direction * delta

func _on_timer_timeout() -> void:
	queue_free()
