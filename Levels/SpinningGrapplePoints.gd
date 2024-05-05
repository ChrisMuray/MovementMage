extends Node3D

const speed = 1.0

func _physics_process(delta):
	rotate_y(delta * speed)
