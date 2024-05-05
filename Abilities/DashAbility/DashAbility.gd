extends Node

# A dash tweens the velocity from the dash speed to 0.35x the dash speed,
# so you launch forward but also slow down. Feels more controllable at 
# the cost of killing your speed.

@export var dash_strength := 35.0    # dash strength
@export var charge_rate := 0.5       # how fast the dash recharges
@export var y_vel_scale := 0.7       # nerfs ability for players to dash up.
@export var endVelMultiplier := 0.35

@onready var playerNode: Player = get_parent().get_parent()
@onready var playerCamNode: Camera3D = get_node("../../CameraPivot/Camera3D")

var has_touched_surface := true
var charge := 3.0
var dashTween: Tween = null

var currentDashVelocity := Vector3(0,0,0)


func reset_charge():
	charge = 3.0

func cancel_dash():
	if dashTween:
		dashTween.kill()
		dashTween = null

		# set velocity to final 0.35x dash speed if cancelled.
		var speed_cap = currentDashVelocity.length() * endVelMultiplier
		if playerNode.velocity.length() > speed_cap:
			playerNode.velocity = playerNode.velocity.limit_length(speed_cap)

func dash():
	if charge >= 1.0:
		currentDashVelocity = -playerCamNode.global_basis.z * dash_strength
		currentDashVelocity.y *= y_vel_scale

		if dashTween:
			dashTween.kill()
			dashTween = null
		dashTween = get_tree().create_tween()
		dashTween.set_parallel(true)
		playerNode.velocity = currentDashVelocity

		# after 0.15s, tween to 0.35x dash velocity over 0.025s
		dashTween.tween_property(playerNode, "velocity", currentDashVelocity*endVelMultiplier, 0.025).set_delay(0.15)

		charge -= 1.0

func _physics_process(delta):
	if Input.is_action_just_pressed("air_dash"):
		dash()
	if playerNode.is_on_floor() or playerNode.is_on_wall():
		cancel_dash()
	
	charge += charge_rate * delta
	charge = min(charge, 3.0)

