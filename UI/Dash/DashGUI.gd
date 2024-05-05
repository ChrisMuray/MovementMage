extends Control

@onready var playerDashNode: Node = $"../../Abilities/DashAbility"
@onready var duck1Node: TextureRect = $Duck1
@onready var duck2Node: TextureRect = $Duck2
@onready var duck3Node: TextureRect = $Duck3

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var charge = playerDashNode.charge
	duck1Node.position = Vector2(20, posFromVal(charge))
	duck1Node.modulate = modulateFromVal(charge)
	duck2Node.position = Vector2(70, posFromVal(charge-1))
	duck2Node.modulate = modulateFromVal(charge-1)
	duck3Node.position = Vector2(120, posFromVal(charge-2))
	duck3Node.modulate = modulateFromVal(charge-2)
	pass

func posFromVal(v):
	v = clamp(v, 0, 1)
	return 40 * (1-v)

func modulateFromVal(v):
	return Color(1,1,1,0.3) if v < 1 else Color(1,1,1,1)
