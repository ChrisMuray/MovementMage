class_name Player extends CharacterBody3D

# Camera options, go faster -> more FOV
@export var cam_sensitivity := 10.0
@export var fov_limits := Vector2(75.0, 115.0)

# Movement parameters
@export var walking_speed := 5.0
@export var max_ground_speed := 15.0
@export var max_air_speed := 20.0
@export var air_control := 0.2
@export var air_control_directionality := 1.0
@export var jump_height := 1.0
@export var double_jump_count := 1
@export var fall_multiplier := 2.0
@export var grapple_force := 1.0

# Ability scenes
@export var iceblock_scene: PackedScene
@export var fireball_scene: PackedScene
@export var repulsor_scene: PackedScene

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var mouse_motion := Vector2.ZERO
var first_person := true:
	set(val):
		first_person = val
		if first_person:
			cam.make_current()
		else:
			third_person_cam.make_current()
var crouching := false:
	set(val):
		crouching = val
		scale.y = lerp(scale.y, 0.5, 0.5) if val else lerp(scale.y, 1.0, 0.5)
var grappling := false:
	set(val):
		grappling = val
		grapple_path.visible = val
var grapple_point: Vector3
var on_ice := false
var ice_num := 0:
	set(val):
		ice_num = val
		on_ice = ice_num > 0
var repulsor_out := false
var double_jumps_left := 0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var cam: Camera3D = $CameraPivot/Camera3D
@onready var third_person_cam: Camera3D = $CameraPivot/Camera3D/ThirdPersonCam
@onready var raycast: RayCast3D = $CameraPivot/Camera3D/Raycast3D
@onready var info_label: Label = $InfoLabel
@onready var center_of_mass: Node3D = $CenterOfMass
@onready var grapple_path: Path3D = $CenterOfMass/GrapplePath
@onready var arms_animation_player: AnimationPlayer = $CameraPivot/Camera3D/Arms/ArmsAnimationPlayer

func _ready() -> void:
	initialize_grapple_hook()
	if Global.checkpoint_positions:
		global_position = Global.checkpoint_positions[-1]

func _physics_process(delta: float) -> void:
	## DEBUG INFO
	info_label.text = "FPS: " + str(1.0/delta) + \
	"\nSPEED: " + str(snapped(get_real_velocity().length(), 0.01)) + \
	"\nOn Ice: " + str(on_ice) + \
	"\nOn Wall: " + str(is_on_wall_only()) + \
	"\nGrappling: " + str(grappling)
	
	## CAMERA
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		handle_camera_rotation()
	
	if Input.is_action_just_pressed("switch_cam"):
		first_person = not first_person
		
	var current_speed = get_real_velocity().length()
	var target_fov = min(fov_limits.x + max(current_speed - walking_speed, 0) * (fov_limits.y-fov_limits.x)/(max_air_speed - walking_speed), fov_limits.y)
	cam.fov = lerp(cam.fov, target_fov, 0.1)
	
	## MOVEMENT
	
	# Crouching
	crouching = Input.is_action_pressed("crouch")
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var hv = Vector3(velocity.x, 0, velocity.z)
	
	if is_on_floor(): # Ground movement logic
		var target_speed = walking_speed if direction else 0.0
		var target_velocity = target_speed * Vector3(direction.x, 0, direction.z)
		velocity.x = move_toward(velocity.x, target_velocity.x, 0.75)
		velocity.z = move_toward(velocity.z, target_velocity.z, 0.75)
		if on_ice:
			var vel = get_real_velocity()
			var ice_speed_multiplier = 1.0 + 0.01 * direction.normalized().dot(vel.normalized())
			velocity = ice_speed_multiplier * vel
			# So player doesn't get stuck in the middle of ice
			if vel == Vector3.ZERO:
				velocity = direction
		# Cap ground speed
		velocity = velocity.limit_length(max_ground_speed)
	
	else: # Air movement logic
		# Add gravity, fall faster if moving downward for snappier / weightier feel
		velocity.y -= gravity * delta * (fall_multiplier if velocity.y < 0 else 1.0) 

		# Air control
		if direction:
			# 0 when input dir is in same dir as current horizontal velocity,
			# and 1 when in opposite direction.
			var val := .5*(1-hv.normalized().dot(direction.normalized()))
			var old_max_xz_speed = hv.length()
			hv = hv + direction * air_control * (1 + air_control_directionality * val)
			hv = hv.limit_length(max(old_max_xz_speed, max_air_speed))
			velocity.x = hv.x
			velocity.z = hv.z
		# Cap air speed
		velocity = velocity.limit_length(max_air_speed)
	
	# Handle jump.
	if is_on_floor():
		if Input.is_action_pressed("jump"):
			velocity.y = sqrt(jump_height * 2 * gravity)
			double_jumps_left = double_jump_count
	elif double_jumps_left > 0 and Input.is_action_just_pressed("jump"):
		velocity.y = 1.5 * sqrt(jump_height * 2 * gravity)
		double_jumps_left -= 1
	
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
		if not grappling and raycast.is_colliding():
			start_grapple()
			grappling = true
		elif grappling:
			grapple()
	
	if Input.is_action_just_released("grapple"):
		grappling = false
	
	if Input.is_action_just_pressed("thumbs_up"):
		arms_animation_player.play("ThumbsUp")
	
	if Input.is_action_just_pressed("die"):
		die()
	
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_motion = -event.relative * 0.001

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
	if crouching:
		proj.scale.y = 2
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
				var displacement = center_of_mass.global_position - c.global_position
				var distance = clampf(displacement.length(), 0, c.explode_radius)
				var launch_direction = displacement.normalized()
				velocity += c.explode_force * c.force_curve.sample(distance / c.explode_radius) * launch_direction
				c.queue_free()
		repulsor_out = false

func initialize_grapple_hook() -> void:
	# Curve to draw grapple line
	var grapple_curve = Curve3D.new()
	grapple_curve.add_point(Vector3.ZERO)
	grapple_curve.add_point(Vector3.ZERO)
	grapple_path.curve = grapple_curve
	
	# Placeholder grapple hook
	var grapple_shape = CSGPolygon3D.new()
	grapple_shape.polygon = PackedVector2Array([
		Vector2(-0.05, -0.05),
		Vector2(-0.05, 0.05),
		Vector2(0.05, 0.05),
		Vector2(0.05, -0.05)
	])
	grapple_shape.mode = CSGPolygon3D.MODE_PATH
	grapple_shape.path_local = true
	grapple_shape.set_path_node(grapple_path.get_path())
	grapple_path.add_child(grapple_shape)

func start_grapple() -> void:
	grapple_point = raycast.get_collision_point()
	grapple()

func grapple() -> void:
	grapple_path.curve.set_point_position(0, Vector3.ZERO)
	grapple_path.curve.set_point_position(1, grapple_path.to_local(grapple_point))
	velocity += (grapple_point - global_position).normalized() * grapple_force

func die() -> void:
	Global.first_load = false
	get_tree().reload_current_scene()
