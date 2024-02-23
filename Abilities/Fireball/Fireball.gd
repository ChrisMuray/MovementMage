extends Area3D

@export var speed := 50.0
var direction: Vector3

func _physics_process(delta: float) -> void:
	position += (speed * direction) * delta

func _on_timer_timeout() -> void:
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	queue_free()
