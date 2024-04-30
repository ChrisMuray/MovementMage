@icon("res://icon.svg") # sets the icon

extends Node
class_name IcePathAbility

var icedShader: ShaderMaterial = preload("res://materials/iced.tres")

var numIces := 50
var ices := []
var nextIce := 0

var debounce := 0
var debounceCount := 1 # no debounce

var numIcesTouchingPlayer := 0


@onready var player: Player = get_parent().get_parent()

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(numIces):
		var ice = load("res://Abilities/IcePathAbility/IceBlock/IceBlock.tscn").instantiate()
		add_child(ice)
		ices.append(ice)


func onIce():
	return numIcesTouchingPlayer > 0

func placeIce(pos):
	# only place ice every other physics frame
	# hacky way to make ice last longer - temporary fix
	if debounce % debounceCount == 0:
		ices[nextIce].rePlace(pos)
		nextIce = (nextIce + 1) % numIces

	debounce += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var sizes = []
	var positions = []
	for i in range(numIces):
		sizes.append(ices[i].size)
		positions.append(ices[i].position)
	icedShader.set_shader_parameter("radii", sizes)
	icedShader.set_shader_parameter("nodes", positions)

func _physics_process(_delta):
	if Input.is_action_pressed("ice_path"):
		if player.raycast.is_colliding() and \
		not player.raycast.get_collider() is IceBlock:
			placeIce(player.raycast.get_collision_point())
