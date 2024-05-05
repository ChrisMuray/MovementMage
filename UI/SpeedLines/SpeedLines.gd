extends ColorRect

@export var maxLineDensity := 0.24 # maximum line density
@export var minSpeed       := 10.0 # player speed at which lines begin to appear (roughly)
@export var maxSpeed       := 35.0 # speed at which line density maxes out

@onready var playerNode := $"../../"

func _process(_delta):
	var playerSpeed = playerNode.velocity.length()
	var ratio = min(1.0, (playerSpeed - minSpeed) / (maxSpeed - minSpeed))
	material.set_shader_parameter("line_density", maxLineDensity * ratio)
	material.set_shader_parameter("line_color", Color(1.0, 1.0, 1.0, ratio))
