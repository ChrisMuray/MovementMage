extends Node3D
class_name GrappleableObject

const hoveredMaterial: Material = preload("res://Environment/GrappleableObject/GrappleableObjectHovered.tres")

@onready var meshInstanceNode: MeshInstance3D = $MeshInstance3D
@onready var collisionShapeNode: CollisionShape3D = $CollisionShape3D

var isLookedAt: bool = false
const lookAtScaleFactor: float = 1.4

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func on_look_at():
	isLookedAt = true
	collisionShapeNode.scale = Vector3(lookAtScaleFactor, lookAtScaleFactor, lookAtScaleFactor)
	meshInstanceNode.material_override = hoveredMaterial

func on_look_away():
	isLookedAt = false
	collisionShapeNode.scale = Vector3(1, 1, 1)
	meshInstanceNode.material_override = null