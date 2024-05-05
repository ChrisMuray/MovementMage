extends Node3D

@onready var pillarNode: AnimatableBody3D = $"Pillar"
@onready var collisionShapeNode: CollisionShape3D = $"Pillar/CollisionShape3D"
@onready var velocityAreaNodeE: Area3D = $"Pillar/VelocityArea"
@onready var velocityAreaNode: CollisionShape3D = $"Pillar/VelocityArea/CollisionShape3D"
@onready var meshNode: Node3D = $"Pillar/RockPillar"

var collidedPlayer: Player = null

func _ready():
	meshNode.rotate_x(randf_range(-0.1, 0.1))
	meshNode.rotate_z(randf_range(-0.1, 0.1))

	# nasty tween
	collisionShapeNode.disabled = true
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(pillarNode, "position", Vector3(0, 5, 0), 0.4)
	tween.tween_callback(swapCollision)
	tween.tween_interval(3)
	tween.set_ease(Tween.EASE_IN).tween_property(pillarNode, "position", Vector3(0, 0, 0), 1.0)
	tween.tween_callback(queue_free)

func _physics_process(_delta):
	if collidedPlayer:
		collidedPlayer.velocity.y = max(16, collidedPlayer.velocity.y)

func swapCollision():
	collisionShapeNode.disabled = false
	velocityAreaNode.disabled = true

func _on_velocity_area_body_entered(body):
	if body is Player:
		collidedPlayer = body

func _on_velocity_area_body_exited(body):
	if body is Player:
		collidedPlayer = null
