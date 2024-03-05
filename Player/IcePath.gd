extends Node

@export var iceblock_scene: PackedScene
@export var use_time := 4.0
@export var cool_time := 2.0
@export var replenish_time := 8.0

# Keeps track of iceblock collisions to tell whether player is on ice
var ice_num := 0:
	set(val):
		ice_num = val
		on_ice = ice_num > 0

var on_ice := false

# Boolean state for cooling down that shuts itself off
var cooling := false:
	set(val):
		cooling = val
		if cooling:
			await get_tree().create_timer(cool_time).timeout
			cooling = false

@onready var player: Player = get_parent()
@onready var spray_sound: AudioStreamPlayer = $Ice_path_spray
@onready var ice_chime: AudioStreamPlayer = $Ice_path_use
func _physics_process(delta: float) -> void:
	if cooling: return
	
	if Input.is_action_pressed("ice_path"):
		player.gui.ice_bar.progress -= delta / use_time
		
		
		if player.gui.ice_bar.progress == 0:
			cooling = true
			spray_sound.stop()
		elif player.raycast.is_colliding() and \
		not player.raycast.get_collider() is IceBlock:
			place_ice()
			
	else:
		player.gui.ice_bar.progress += delta / replenish_time
	ice_sound()
func place_ice() -> void:
	var normal = player.raycast.get_collision_normal()
	if normal.y <= 0: # Can't place ice on ceiling
		return
	var point = player.raycast.get_collision_point()
	var local_point = player.to_local(point)
	#Needed for proper rotation
	var up = Vector3.RIGHT if normal == Vector3.UP else Vector3.UP
	var new_iceblock = iceblock_scene.instantiate()
	add_child(new_iceblock)
	new_iceblock.global_position = point
	new_iceblock.look_at(point+normal, up)
	
func ice_sound() -> void:
	if Input.is_action_just_pressed("ice_path"):
		ice_chime.play()
		spray_sound.play(4.0 - 4.0*player.gui.ice_bar.progress)
			
		
	elif Input.is_action_just_released("ice_path"):
		spray_sound.stop()
