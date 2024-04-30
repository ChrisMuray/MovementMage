@icon("res://icon.svg") # sets the icon

extends Node3D

const grappleProgressCurve = preload("res://Abilities/GrappleAbility/GrappleProgressCurve.tres")

@onready var pathNode: Path3D = $GrapplePath
@onready var player: Player = get_parent().get_parent()
@onready var cameraNode: Camera3D = get_node("../../CameraPivot/Camera3D")
@onready var rayCastNode: RayCast3D = get_node("../../CameraPivot/Camera3D/Raycast3D")

var lookedAtNode: GrappleableObject = null
var grappledNode: GrappleableObject = null
var isGrappling: bool = false

const grappleReachSpeed: float = 3.0
var grappleReachProgress: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	initGrapple()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if isGrappling:
		var wandPos = cameraNode.to_global(Vector3(0.794, 0.189, -0.584))
		var startPoint = to_local(wandPos)
		var endPoint = to_local(grappledNode.global_transform.origin)
		var dist = grappleProgressCurve.sample(grappleReachProgress)
		pathNode.curve.set_point_position(0, startPoint)
		pathNode.curve.set_point_position(1, startPoint.lerp(endPoint,dist))

func _physics_process(delta):
	if isGrappling:
		updateGrapple(delta)
	else:
		checkLookedAtNode()

	if Input.is_action_just_pressed("grapple") and not isGrappling:
		startGrapple()
	elif Input.is_action_just_released("grapple") and isGrappling:
		endGrapple()

func checkLookedAtNode():
	if rayCastNode and rayCastNode.is_colliding():
		var collidedNode = rayCastNode.get_collider()
		if collidedNode is GrappleableObject:
			if lookedAtNode != null: lookedAtNode.on_look_away()
			lookedAtNode = collidedNode
			lookedAtNode.on_look_at()
	else:
		if lookedAtNode != null:
			lookedAtNode.on_look_away()
			lookedAtNode = null

func initGrapple():
	pathNode.curve = Curve3D.new()
	pathNode.curve.add_point(Vector3.ZERO)
	pathNode.curve.add_point(Vector3.ZERO)

	var grapple_shape = CSGPolygon3D.new()
	grapple_shape.polygon = PackedVector2Array([
		Vector2(-0.05, -0.05),
		Vector2(-0.05, 0.05),
		Vector2(0.05, 0.05),
		Vector2(0.05, -0.05)
	])

	print("inited")

	# halve its opacity
	grapple_shape.material_override = StandardMaterial3D.new()
	grapple_shape.material_override.albedo_color = Color(0, 1, 0, 0.15)
	grapple_shape.material_override.flags_unshaded = true
	grapple_shape.material_override.flags_transparent = true
	grapple_shape.material_override.flags_do_not_receive_shadows = true

	grapple_shape.mode = CSGPolygon3D.MODE_PATH
	grapple_shape.path_local = true
	grapple_shape.set_path_node(pathNode.get_path())
	pathNode.add_child(grapple_shape)

func startGrapple():
	if lookedAtNode != null:
		grappledNode = lookedAtNode
		isGrappling = true
		grappleReachProgress = 0.0

func endGrapple():
	if lookedAtNode != null:
		pathNode.curve.set_point_position(0, Vector3.ZERO)
		pathNode.curve.set_point_position(1, Vector3.ZERO)
		isGrappling = false
		grappleReachProgress = 0.0

func updateGrapple(delta):
	if isGrappling:
		if grappleReachProgress >= 1.0:
			grappleReachProgress = 1.0
			# apply playerphysics
			var offset = (grappledNode.global_transform.origin - player.global_transform.origin)
			var direction = offset.normalized()
			var strength = clampf(offset.length() - 3, 0, 100)

			player.velocity += direction * strength * 20 * delta
			player.velocity += Vector3(0, -5, 0) * delta # reduce gravity
		else:
			grappleReachProgress += delta * grappleReachSpeed;
