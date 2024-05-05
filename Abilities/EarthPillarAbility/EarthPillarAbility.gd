extends Node

const earthPillarTscn: PackedScene = preload("./EarthPillar/EarthPillar.tscn")
@onready var playerNode: Player = $"../../"

func spawn_pillar():
	var pillar = earthPillarTscn.instantiate()
	pillar.position = playerNode.position
	get_tree().current_scene.add_child(pillar)
