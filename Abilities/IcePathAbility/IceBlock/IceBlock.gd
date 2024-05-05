extends Node3D
class_name IceBlock

const sizeCurve := preload("./IceSizeCurve.tres")
@onready var collider = $Area3D/CollisionShape3D
@onready var meshInstance = $MeshInstance3D

var lifetime := 3.0
var spawnTime := 0.0
var maxSize := 4.0
var size := 0.0

func rePlace(pos: Vector3):
	position = pos
	spawnTime = Time.get_ticks_msec() / 1000.0

func _ready():
	spawnTime = Time.get_ticks_msec() / 1000.0
	position = Vector3(0, -100, 0)

func _process(_delta):
	pass

func _physics_process(_delta):
	var aliveTime := Time.get_ticks_msec() / 1000.0 - spawnTime

	if aliveTime > lifetime:
		position = Vector3(0, -100, 0)
		return

	size = sizeCurve.sample(aliveTime / lifetime)
	collider.shape.radius = size * maxSize
	meshInstance.scale = Vector3(size, size, size)
	
func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		body.icePathAbility.numIcesTouchingPlayer += 1

func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		body.icePathAbility.numIcesTouchingPlayer -= 1
