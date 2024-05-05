extends MeshInstance3D

var material = load("res://Assets/Materials/Gemstone.tres")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func setColor(color):
	material.set("shader_parameter/fresnel_color", color.rgb)
