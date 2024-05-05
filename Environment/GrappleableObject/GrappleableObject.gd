extends Node3D
class_name GrappleableObject

@onready var meshInstanceNode: MeshInstance3D = $"MeshInstance3D"
@onready var collisionShapeNode: CollisionShape3D = $"CollisionShape3D"
const hoveredMaterial: Material = preload("./GrappleableObjectHovered.tres")

var isLookedAt: bool = false

# the hitbox size gets bigger if the object is looked at.
# this makes it harder to accidentally lose focus on the target.
const lookAtScaleFactor: float = 1.4

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