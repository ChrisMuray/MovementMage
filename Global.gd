extends Node

var first_load := true
var checkpoint_positions = []

func add_checkpoint_position(cpp) -> void:
	if not cpp in checkpoint_positions:
		checkpoint_positions.append(cpp)
