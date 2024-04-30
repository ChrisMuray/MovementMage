extends ColorRect

@onready var playerNode := get_parent().get_parent()

var lineDensity : float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var playerVel = playerNode.velocity
	var ratio = min(1.0, (playerVel.length() - 10) / 25.0)
	material.set_shader_parameter("line_density", 0.24 * ratio)
	material.set_shader_parameter("line_color", Color(1.0, 1.0, 1.0, ratio))
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	pass
