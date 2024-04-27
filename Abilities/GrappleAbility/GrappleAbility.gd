extends Node3D

@onready var rayCastNode: RayCast3D = $RayCast
@onready var pathNode: Path3D = $GrapplePath
@onready var player: Player = get_parent().get_parent() # LOL

var lookedAtNode: GrappleableObject = null
var grappledNode: GrappleableObject = null
var isGrappling: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	initGrapple()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if isGrappling:
		pathNode.curve.set_point_position(0, to_local(global_transform.origin - Vector3(0, 0.5, 0)))
		pathNode.curve.set_point_position(1, to_local(grappledNode.global_transform.origin))

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
	if rayCastNode.is_colliding():
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
	pathNode.curve.add_point(Vector3(0, -1, 0))
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

func endGrapple():
	if lookedAtNode != null:
		pathNode.curve.set_point_position(1, Vector3.ZERO)
		isGrappling = false

func updateGrapple(delta):
	if isGrappling:
		# apply playerphysics
		var offset = (grappledNode.global_transform.origin - global_transform.origin)
		var direction = offset.normalized()
		var strength = clampf(offset.length() - 3, 0, 100)

		player.velocity += direction * strength * 20 * delta
		player.velocity += Vector3(0, -5, 0) * delta # reduce gravity
