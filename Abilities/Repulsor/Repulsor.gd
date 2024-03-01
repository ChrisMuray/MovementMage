class_name Repulsor extends CharacterBody3D

@export var shoot_time := 2.0
@export var starting_speed := 500.0
@export var speed_curve: Curve
@export var rotation_speed := 10.0
@export var explode_radius := 10.0
@export var explode_force := 20.0
@export var force_curve : Curve

var direction: Vector3
var t := 0.0
var movin := true
var angular_velocity: Vector3

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var spawn_velocity: Vector3 = get_parent().get_real_velocity() 
@onready var explode_audio: AudioStreamPlayer3D = $ExplodeAudio

func _ready() -> void:
	angular_velocity = rotation_speed * Vector3(randf(), randf(), randf()).normalized()

func _physics_process(delta: float) -> void:
	if movin:
		var progress = t / shoot_time
		velocity = delta * speed_curve.sample(progress) * direction * starting_speed + 50.0 * delta * spawn_velocity
		t += delta
		movin = t <= shoot_time
	else:
		velocity = Vector3.ZERO
	mesh.rotation += delta * angular_velocity
	move_and_slide()

func explode(p: Player):
	var displacement = p.center_of_mass.global_position - global_position
	var distance = clampf(displacement.length(), 0, explode_radius)
	var launch_direction = displacement.normalized()
	var impulse = explode_force * force_curve.sample(distance / explode_radius) * launch_direction
	if p.grapple_hook.grappling:
		p.grapple_hook.swing_node.apply_central_impulse(impulse)
	else:	
		p.velocity += impulse
	explode_audio.play()
	visible = false


func _on_explode_audio_finished() -> void:
	queue_free()
