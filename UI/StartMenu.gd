extends Control

var paused := true:
	set(val):
		paused = val
		get_tree().paused = paused
		visible = paused
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED

func _ready() -> void:
	paused = Global.first_load

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		paused = not paused

func _on_start_button_pressed() -> void:
	paused = false
