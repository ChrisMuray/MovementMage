extends Area3D

var reached := false:
	set(val):
		reached = val
		var mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(Color.AQUA, 0.25)
		mesh.material_override = mat
		Global.add_checkpoint_position(global_position)

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	if global_position in Global.checkpoint_positions:
		reached = true

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		if not reached:
			reached = true
