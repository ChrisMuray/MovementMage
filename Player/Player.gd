extends CharacterBody3D

@export var speed := 5.0
@export var jump_height := 1.0
@export var fall_multiplier := 2.0
@export var max_hitpoints := 100
@export var cam_sensitivity := 10.0
@export var iceblock_scene: PackedScene
@export var fireball_scene: PackedScene
@export var repulsor_scene: PackedScene
@export var fireball_speed := 10.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var mouse_motion := Vector2.ZERO
var crouching := false:
	set(val):
		crouching = val
		scale.y = lerp(scale.y, 0.5, 0.5) if val else lerp(scale.y, 1.0, 0.5)
var grappling := false:
	set(val):
		grappling = val
		grapple_path.visible = val
var on_ice := false
var ice_num := 0:
	set(val):
		ice_num = val
		on_ice = ice_num > 0
var repulsor_out := false

@onready var camera_pivot: Node3D = $CameraPivot
@onready var cam: Camera3D = $CameraPivot/Camera3D
@onready var raycast: RayCast3D = $CameraPivot/Camera3D/Raycast3D

@onready var crosshair: Control = $CenterContainer/Crosshair
@onready var info_label: Label = $InfoLabel
@onready var center_of_mass: Node3D = $CenterOfMass
@onready var grapple_path: Path3D = $CenterOfMass/GrapplePath

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	var grapple_curve = Curve3D.new()
	grapple_curve.add_point(Vector3.ZERO)
	grapple_curve.add_point(Vector3.ZERO)
	grapple_path.curve = grapple_curve
	var grapple_shape = CSGPolygon3D.new()
	grapple_shape.polygon = PackedVector2Array([
		Vector2(-0.05, -0.05),
		Vector2(-0.05, 0.05),
		Vector2(0.05, 0.05),
		Vector2(0.05, -0.05)
	])
	grapple_shape.mode = CSGPolygon3D.MODE_PATH
	grapple_shape.set_path_node(grapple_path.get_path())
	grapple_path.add_child(grapple_shape)

func _physics_process(delta: float) -> void:
	
	## DEBUG INFO
	info_label.text = "FPS: " + str(1.0/delta) + \
	"\nSPEED: " + str(snapped(get_real_velocity().length(), 0.01)) + \
	"\nOn Ice: " + str(on_ice) + \
	"\nOn Wall: " + str(is_on_wall_only())
	
	## CAMERA
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		handle_camera_rotation()
	
	
	## MOVEMENT
	# Add the gravity.
	if not is_on_floor():
		if velocity.y >= 0:
			velocity.y -= gravity * delta
		else:
			velocity.y -= gravity * delta * fall_multiplier # faster fall downward for snappier feel
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = sqrt(jump_height * 2 * gravity)
	
	# Crouching
	crouching = Input.is_action_pressed("crouch")
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var current_speed = get_real_velocity().length()
	
	if on_ice:
		current_speed = clamp(1.01 * get_real_velocity().length(), 0, 30.0)
	else:
		current_speed = lerp(current_speed, speed, 0.1)
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = 0
		velocity.z = 0
	
	## ABILITIES
	if Input.is_action_just_pressed("fireball"):
		shoot(fireball_scene)
	
	if Input.is_action_pressed("ice_path"):
		if raycast.is_colliding():
			if not raycast.get_collider() is IceBlock:
				place_ice()
	
	if Input.is_action_just_pressed("repulse"):
		handle_repulsor()
	
	if Input.is_action_pressed("grapple"):
		grappling = true
		grapple()
	else:
		grappling = false
	
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_motion = -event.relative * 0.001
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func handle_camera_rotation() ->void:
	rotate_y(mouse_motion.x * cam_sensitivity)
	camera_pivot.rotate_x(mouse_motion.y * cam_sensitivity)
	camera_pivot.rotation_degrees.x = clampf(
		camera_pivot.rotation_degrees.x, -90.0, 90.0
	)
	mouse_motion = Vector2.ZERO

func place_ice() -> void:
	var normal = raycast.get_collision_normal()
	if normal.y <= 0:
		return
	var point = raycast.get_collision_point()
	var local_point = to_local(point)
	
	#Needed for proper rotation
	var up = Vector3.RIGHT if normal == Vector3.UP else Vector3.UP
	
	var new_iceblock = iceblock_scene.instantiate()
	new_iceblock.position = local_point
	if crouching:
		new_iceblock.scale.y = 2
	add_child(new_iceblock)
	new_iceblock.look_at(point+normal, up)

func shoot(scene: PackedScene) -> void:
	var proj = scene.instantiate()
	var dir = -cam.global_basis.z
	add_child(proj)
	proj.global_position = cam.global_position + dir
	proj.direction = dir

func handle_repulsor() -> void:
	if not repulsor_out:
			repulsor_out = true
			shoot(repulsor_scene)
	else:
		for c in get_children():
			if c is Repulsor:
				var displacement = global_position + Vector3.UP - c.global_position
				var distance = clampf(displacement.length(), 0, c.explode_radius)
				var launch_direction = displacement.normalized()
				velocity += c.explode_force * c.force_curve.sample(distance / c.explode_radius) * launch_direction
				c.queue_free()
		repulsor_out = false

func grapple() -> void:
	if not raycast.is_colliding():
		return
	
	var global_point = center_of_mass.to_local(raycast.get_collision_point())
	grapple_path.curve.set_point_position(0, center_of_mass.to_local(Vector3.ZERO))
	grapple_path.curve.set_point_position(1, center_of_mass.to_local(global_point))
	for i in range(grapple_path.curve.point_count):
		print(grapple_path.curve.get_point_position(i))
