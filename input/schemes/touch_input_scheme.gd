class_name TouchInputScheme
extends InputScheme
## Touch: on-screen movement joystick. Ability sticks arrive in M2.

## Root of the on-screen touch UI; shown only while this scheme is active.
@export var controls: CanvasLayer
@export var move_stick: VirtualJoystick


func _ready() -> void:
	_set_controls_enabled(false)


func _physics_process(_delta: float) -> void:
	if not is_active:
		return
	_update_analog_move(move_stick.output)


func _on_activated() -> void:
	_set_controls_enabled(true)


func _on_deactivated() -> void:
	_set_controls_enabled(false)


func _set_controls_enabled(enabled: bool) -> void:
	if controls != null:
		controls.visible = enabled
	if move_stick != null:
		move_stick.enabled = enabled
