extends MeshInstance3D
class_name Gem

var material: ShaderMaterial = preload("res://Assets/Materials/Gemstone.tres")

var currentColor: Color = material.get_shader_parameter("base_color")
var originalColor: Color = currentColor
var targetColor: Color = currentColor

var pulseTween: Tween = null

func _ready():
	pass

func _process(delta):
	currentColor = currentColor.lerp(targetColor, 8.0 * delta)

	# TODO: which colors to set
	material.set("shader_parameter/base_color", currentColor)
	material.set("shader_parameter/fresnel_color", currentColor)
	
func setColor(color: Color):
	targetColor = color
	
func resetColor():
	targetColor = originalColor

func pulseColor(color: Color, duration: float):
	# TODO
	pass