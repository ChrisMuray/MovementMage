class_name Player extends CharacterBody3D

# Camera options, go faster -> more FOV
@export var cam_sensitivity := 2.0

# Movement parameters
@export var walking_speed := 8.0
@export var max_ground_speed := 20.0
@export var max_air_speed := 35.0
@export var air_control := 0.05
@export var air_control_directionality := 0.0
@export var jump_height := 1.5
@export var double_jump_count := 1
@export var gravity_multiplier := 1.75
@export var fall_multiplier := 2.0

# Ability scenes
@export var fireball_scene: PackedScene

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_multiplier
var mouse_motion := Vector2.ZERO
var first_person := true:
	set(val):
		first_person = val
		arm_viewport.visible = first_person
		if first_person:
			cam.make_current()
		else:
			third_person_cam.make_current()

@onready var camera_pivot: Node3D = $CameraPivot
@onready var cam: Camera3D = $CameraPivot/Camera3D
@onready var third_person_cam: Camera3D = $CameraPivot/Camera3D/ThirdPersonCam
@onready var raycast: RayCast3D = $CameraPivot/Camera3D/Raycast3D
@onready var info_label: Label = $InfoLabel
@onready var center_of_mass: Node3D = $CenterOfMass
# @onready var grapple_hook: Path3D = $GrappleHook
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var collider: CollisionShape3D = $CollisionShape3D
@onready var arm_viewport: SubViewportContainer = $ArmViewport
@onready var gui: Control = $GUI

var render_debug_text = ""
var physics_debug_text = ""

@onready var repulse: Node = $Repulse
@onready var icePathAbility: Node = $Abilities/IcePathAbility



func _ready() -> void:
	# Respawn point
	if Global.checkpoint_positions:
		global_position = Global.checkpoint_positions[-1]

func _process(delta: float) -> void:
	render_debug_text = "FPS: " + str(1.0/delta) + "\n"
	info_label.text = render_debug_text + physics_debug_text
	
	## CAMERA
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		handle_camera_rotation()

func _physics_process(delta: float) -> void:	
	if Input.is_action_just_pressed("switch_cam"):
		first_person = not first_person
			
	## MOVEMENT
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var hv = Vector3(velocity.x, 0, velocity.z)
	
	if is_on_floor(): # Ground movement logic
		var target_speed = walking_speed if direction else 0.0
		var target_velocity = target_speed * Vector3(direction.x, 0, direction.z)
		var real_velocity = velocity # grab velocity before move_toward

		var new_hv = hv.move_toward(target_velocity, 80 * delta)

		velocity.x = new_hv.x
		velocity.z = new_hv.z

		if icePathAbility.onIce():
			var ice_speed_multiplier = 1.0 + 0.01 * direction.normalized().dot(real_velocity.normalized())
			velocity = ice_speed_multiplier * real_velocity
			# So player doesn't get stuck in the middle of ice
			if real_velocity == Vector3.ZERO:
				velocity = direction
		# Cap ground speed
		velocity = velocity.limit_length(max_ground_speed)
	
	else:
		# Add gravity, fall faster if moving downward for snappier / weightier feel
		velocity.y -= gravity * delta * (fall_multiplier if velocity.y < 0 else 1.0) 
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
	if Input.is_action_pressed("jump"):
		jump(direction)
	

		## DEBUG INFO
	physics_debug_text = "Physics FPS: " + str(1.0/delta) + \
	"\nSPEED: " + str(snapped(get_real_velocity().length(), 0.01)) + \
	"\non ice: " + str(icePathAbility.onIce()) + \
	"\non ground: " + str(is_on_floor()) + \
	"\nvelocity: " + str(velocity) + \
	"\ndirection: " + str(direction)

	move_and_slide()

	var platform_rot = get_platform_angular_velocity()
	rotate_y(delta * platform_rot.y)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_motion = -event.relative * 0.001
		
	## ABILITIES
	if Input.is_action_just_pressed("fireball"):
		shoot(fireball_scene)
	
	if Input.is_action_just_pressed("die"):
		die()


func handle_camera_rotation() ->void:
	rotate_y(mouse_motion.x * cam_sensitivity)
	camera_pivot.rotate_x(mouse_motion.y * cam_sensitivity)
	camera_pivot.rotation_degrees.x = clampf(
		camera_pivot.rotation_degrees.x, -90.0, 90.0
	)
	mouse_motion = Vector2.ZERO

func jump(dir) -> void:
	if is_on_floor():
			velocity.y = sqrt(jump_height * 2 * gravity)
			dir.y = 0
			var hv = velocity
			hv.y = 0
			hv = hv.lerp(dir * 2, 0.5)
			velocity.x = hv.x
			velocity.z = hv.z

func shoot(scene: PackedScene) -> void:
	var proj = scene.instantiate()
	var dir = -cam.global_basis.z
	var offset = cam.global_basis.x

	add_child(proj)
	proj.global_position = cam.global_position + offset + dir
	proj.direction = dir
	proj.look_at(proj.global_position - dir)

func die() -> void:
	Global.first_load = false
	get_tree().reload_current_scene()
