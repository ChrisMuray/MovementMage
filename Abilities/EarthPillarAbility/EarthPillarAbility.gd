extends Node

const earthPillarTscn: PackedScene = preload("./EarthPillar/EarthPillar.tscn")
@onready var playerNode: Player = $"../../"
# TODO add gem color change
#@onready var gemNode: GDScript = playerNode
@export var animDelay := 0.75

func spawn_pillar():
	# No animation events means we have to time the delay ourselves
	await get_tree().create_timer(animDelay).timeout
	var pillar = earthPillarTscn.instantiate()
	pillar.position = playerNode.position
	get_tree().current_scene.add_child(pillar)
