extends Path3D

var grappling := false:
	set(val):
		grappling = val
		player.collider.disabled = grappling
		collider.disabled = not grappling
		visible = grappling
var grapple_point: Vector3
var joint: PinJoint3D

@onready var player: Player = get_parent()
@onready var grapple_node: StaticBody3D = $GrappleNode
@onready var swing_node: RigidBody3D = $SwingNode
@onready var collider: CollisionShape3D = $SwingNode/CollisionShape3D

func _ready() -> void:
	initialize_grapple_hook()

func _physics_process(_delta: float) -> void:

	if Input.is_action_just_pressed("grapple") and not grappling and player.raycast.is_colliding():
		start_grapple(player.raycast.get_collision_point())
	if Input.is_action_pressed("grapple") and grappling:
		grapple()
	if Input.is_action_just_released("grapple") and grappling:
		stop_grapple()

func initialize_grapple_hook() -> void:
	# Initialize curve to draw line
	var grapple_curve = Curve3D.new()
	grapple_curve.add_point(Vector3.ZERO)
	grapple_curve.add_point(Vector3.ZERO)
	curve = grapple_curve
	
	# Placeholder grapple hook mesh
	var grapple_shape = CSGPolygon3D.new()
	grapple_shape.polygon = PackedVector2Array([
		Vector2(-0.05, -0.05),
		Vector2(-0.05, 0.05),
		Vector2(0.05, 0.05),
		Vector2(0.05, -0.05)
	])
	grapple_shape.mode = CSGPolygon3D.MODE_PATH
	grapple_shape.path_local = true
	grapple_shape.set_path_node(get_path())
	add_child(grapple_shape)

func start_grapple(point: Vector3) -> void:
	if point.y < player.center_of_mass.global_position.y:
		return
	
	grappling = true
	grapple_point = point
	grapple_node.global_position = point
	swing_node.global_position = player.center_of_mass.global_position
	swing_node.linear_velocity = player.get_real_velocity()
	
	var new_joint = PinJoint3D.new()
	grapple_node.add_child(new_joint)
	new_joint.global_position = grapple_node.global_position
	new_joint.node_a = grapple_node.get_path()
	new_joint.node_b = swing_node.get_path()
	joint = new_joint
	grapple()

func stop_grapple() -> void:
	grappling = false
	if joint: joint.queue_free()
	player.velocity = 1.5 * swing_node.linear_velocity

func grapple() -> void:
	curve.set_point_position(0, Vector3.ZERO)
	curve.set_point_position(1, to_local(grapple_point))
	
