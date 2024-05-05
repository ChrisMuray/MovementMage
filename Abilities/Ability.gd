extends Node
class_name Ability

# Commonly-used player references.
@onready var playerNode: Player = $"../../"
@onready var cameraNode: Camera3D = $"../../CameraPivot/Camera3D"
@onready var rayCastNode: RayCast3D = $"../../CameraPivot/Camera3D/Raycast3D"
@onready var gemNode: Gem = $"../../CameraPivot/Camera3D/Arms/Armature/Skeleton3D/Gem"

# UI reference
@onready var guiNode: Control = $"../../GUI"


func _ready():
	# (make sure that ability nodes are in the right place)
	assert(playerNode is Player)


# TODO: are these needed? could just call gemNode.setColor in inherited class.
# Setting Gem Color
func setGemColor(color: Color):
	gemNode.setColor(color)
func resetGemColor():
	gemNode.resetColor()
func pulseGemColor(color: Color, duration: float):
	gemNode.pulseColor(color, duration)

# TODO: common interface for ability ready(), cooldowns, buffers, etc.