class_name GamepadInputScheme
extends InputScheme
## Gamepad: left stick moves. Right-stick aim and trigger/bumper abilities
## arrive in M2.


func _physics_process(_delta: float) -> void:
	if not is_active:
		return
	var stick: Vector2 = Input.get_vector(
		InputActions.MOVE_LEFT,
		InputActions.MOVE_RIGHT,
		InputActions.MOVE_UP,
		InputActions.MOVE_DOWN
	)
	_update_analog_move(stick)
