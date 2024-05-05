extends Node

const earthPillarTscn: PackedScene = preload("./EarthPillar/EarthPillar.tscn")
@onready var playerNode: Player = $"../../"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func spawn_pillar():
	if not playerNode.is_on_floor():
		return

	print("yo")
	var pillar = earthPillarTscn.instantiate()
	pillar.position = playerNode.position
	get_tree().current_scene.add_child(pillar)

func _physics_process(_delta):
	# temporary
	if Input.is_action_just_pressed("earth_pillar"):
		spawn_pillar()