extends StaticBody3D

var time := 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _physics_process(delta):
	time += delta
	translate(Vector3(0, 5.0 * sin(time), 0))
	rotate_y(1.5 * delta)

	