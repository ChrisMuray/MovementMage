extends Node
class_name IcePathAbility

const icedShader := preload("./iced.tres")
const iceBlockTscn := preload("./IceBlock/IceBlock.tscn")
@onready var playerNode := $"../../"

var casting := false

var numIces := 50
var ices := []
var nextIce := 0

var numIcesTouchingPlayer := 0

func onIce():
	return numIcesTouchingPlayer > 0

func placeIce(pos):
	ices[nextIce].rePlace(pos)
	nextIce = (nextIce + 1) % numIces

func _ready():
	for i in range(numIces):
		var ice = iceBlockTscn.instantiate()
		add_child(ice)
		ices.append(ice)

func _process(_delta):
	var sizes = []
	var positions = []
	for i in range(numIces):
		sizes.append(ices[i].size)
		positions.append(ices[i].position)
	icedShader.set_shader_parameter("radii", sizes)
	icedShader.set_shader_parameter("nodes", positions)

func _physics_process(_delta):
	if casting:
		if playerNode.raycast.is_colliding() and \
		not playerNode.raycast.get_collider() is IceBlock:
			placeIce(playerNode.raycast.get_collision_point())
