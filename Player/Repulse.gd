extends Node

@export var repulsor_scene: PackedScene
var repulsor_out := false

@onready var player: Player = get_parent()

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("repulse"):
		if not repulsor_out:
				repulsor_out = true
				player.shoot(repulsor_scene)
		else:
			for c in player.get_children():
				if c is Repulsor:
					c.explode(player)
			repulsor_out = false
