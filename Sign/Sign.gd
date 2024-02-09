@tool
extends Node3D

@export_multiline var text := "Hello, World!":
	set(val):
		text = val
		get_child(1).get_child(0).text = text
