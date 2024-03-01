extends ColorRect

var starting_size: Vector2i

@onready var progress_rect: ColorRect = $ProgressRect

func _ready() -> void:
	starting_size = progress_rect.size
	

@export_range(0.0,1.0) var progress := 1.0:
	set(val):
		progress = clampf(val, 0.0, 1.0)
		progress_rect.set_size(Vector2(progress * starting_size.x, starting_size.y))
