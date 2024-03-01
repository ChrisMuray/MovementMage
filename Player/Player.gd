class_name Player extends CharacterBody3D

# Camera options, go faster -> more FOV
@export var cam_sensitivity := 10.0
@export var fov_limits := Vector2(75.0, 115.0)

# Movement parameters
@export var walking_speed := 10.0
@export var max_ground_speed := 25.0
@export var max_air_speed := 45.0
@export var air_control := 0.2
@export var air_control_directionality := 1.0
@export var jump_height := 2.0
@export var double_jump_count := 1
@export var fall_multiplier := 2.0

# Ability scenes
@export var fireball_scene: PackedScene

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var mouse_motion := Vector2.ZERO
var first_person := true:
	set(val):
		first_person = val
		arm_viewport.visible = first_person
		if first_person:
			cam.make_current()
		else:
			third_person_cam.make_current()
var crouching := false:
	set(val):
		crouching = val
		scale.y = lerp(scale.y, 0.5, 0.5) if val else lerp(scale.y, 1.0, 0.5)
var double_jumps_left := 0

var air_dash := false:
	set(val):
		air_dash = val
		if air_dash:
			await get_tree().create_timer(dash_time).timeout
			velocity = walking_speed*velocity.normalized()
			air_dash = false
var dash_time := 0.2
var dash_speed := 50.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var cam: Camera3D = $CameraPivot/Camera3D
@onready var third_person_cam: Camera3D = $CameraPivot/Camera3D/ThirdPersonCam
@onready var raycast: RayCast3D = $CameraPivot/Camera3D/Raycast3D
@onready var info_label: Label = $InfoLabel
@onready var center_of_mass: Node3D = $CenterOfMass
@onready var grapple_hook: Path3D = $GrappleHook
@onready var animation_player: AnimationPlayer = $CameraPivot/Camera3D/Arms/AnimationPlayer
@onready var collider: CollisionShape3D = $CollisionShape3D
@onready var arm_viewport: SubViewportContainer = $ArmViewport
@onready var gui: Control = $GUI


@onready var ice_path: Node = $IcePath
@onready var repulse: Node = $Repulse

func _ready() -> void:
	# Respawn point
	if Global.checkpoint_positions:
		global_position = Global.checkpoint_positions[-1]

func _physics_process(delta: float) -> void:
	## DEBUG INFO
	info_label.text = "FPS: " + str(1.0/delta) + \
	"\nSPEED: " + str(snapped(get_real_velocity().length(), 0.01)) + \
	"\nOn Ice: " + str(ice_path.on_ice) + \
	"\nOn Wall: " + str(is_on_wall_only()) + \
	"\nGrappling: " + str(grapple_hook.grappling) + \
	"\nAnimation: " + animation_player.current_animation
	
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
		if ice_path.on_ice:
			var vel = get_real_velocity()
			var ice_speed_multiplier = 1.0 + 0.01 * direction.normalized().dot(vel.normalized())
			velocity = ice_speed_multiplier * vel
			# So player doesn't get stuck in the middle of ice
			if vel == Vector3.ZERO:
				velocity = direction
		# Cap ground speed
		velocity = velocity.limit_length(max_ground_speed)
	
	else: # Air movement logic
		if air_dash:
			velocity = dash_speed * direction
		else:
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
	
	# Handle jump
	if Input.is_action_just_pressed("jump"):
		jump()
	
	if Input.is_action_just_pressed("air_dash"):
		if not is_on_floor():
			air_dash = true
	
	## ABILITIES
	if Input.is_action_just_pressed("fireball"):
		shoot(fireball_scene)
	
	if Input.is_action_just_pressed("die"):
		die()
	
	## ANIMATION
	if is_on_floor():
		if Input.is_action_pressed("ice_path"):
			animation_player.play("Skill2Hold")
		elif velocity.length() > 0:
			animation_player.play("Run")
		else:
			if Input.is_action_just_pressed("1"):
				animation_player.play("Skill1")
			elif Input.is_action_pressed("2"):
				animation_player.play("Skill2Hold")
			elif Input.is_action_just_pressed("3"):
				animation_player.play("Skill3")
			elif not animation_player.is_playing():
				animation_player.play("Idle")
	
	if grapple_hook.grappling:
		velocity = Vector3.ZERO
		global_position = grapple_hook.swing_node.global_position - center_of_mass.position
		if Input.is_action_just_pressed("jump"):
			grapple_hook.stop_grapple()
			jump()
	else:
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

func jump() -> void:
	if is_on_floor() or grapple_hook.grappling:
			velocity.y = sqrt(jump_height * 2 * gravity)
			double_jumps_left = double_jump_count
	elif double_jumps_left > 0:
		velocity.y = sqrt(jump_height * 2 * gravity)
		double_jumps_left -= 1

func stop_dash() -> void:
	air_dash = false

func shoot(scene: PackedScene) -> void:
	var proj = scene.instantiate()
	var dir = -cam.global_basis.z
	if crouching:
		proj.scale.y = 2
	add_child(proj)
	proj.global_position = cam.global_position + dir
	proj.direction = dir

func die() -> void:
	Global.first_load = false
	get_tree().reload_current_scene()
