class_name InputScheme
extends Node
## Base class for a control scheme (PC, gamepad, touch).
##
## A scheme reads its own devices and emits PlayerIntents. Only the active
## scheme emits; the InputRouter decides which one is active.

signal intent_emitted(intent: PlayerIntent)

## Camera used to convert screen/stick input into world space. Set by the router.
var camera: Camera3D
var is_active: bool = false

var _last_move_stick: Vector2 = Vector2.ZERO


func activate() -> void:
	if is_active:
		return
	is_active = true
	_on_activated()


func deactivate() -> void:
	if not is_active:
		return
	# Release any analogue movement before going quiet, so the player doesn't
	# keep walking after a scheme switch.
	_update_analog_move(Vector2.ZERO)
	is_active = false
	_on_deactivated()


## Override for scheme-specific setup when it becomes active.
func _on_activated() -> void:
	pass


## Override for scheme-specific cleanup when it stops being active.
func _on_deactivated() -> void:
	pass


func _emit(intent: PlayerIntent) -> void:
	if is_active:
		intent_emitted.emit(intent)


## Emits a MoveDirectionIntent when the stick value changes.
func _update_analog_move(stick: Vector2) -> void:
	if stick.is_equal_approx(_last_move_stick):
		return
	_last_move_stick = stick
	_emit(MoveDirectionIntent.new(_stick_to_world(stick)))


func _stick_to_world(stick: Vector2) -> Vector3:
	if stick == Vector2.ZERO:
		return Vector3.ZERO
	if camera == null:
		return Vector3(stick.x, 0.0, stick.y).limit_length(1.0)
	return InputMath.stick_to_world(stick, camera.global_transform.basis)


## Projects a viewport position onto the ground. Returns Vector3 or null.
func _screen_to_ground(screen_position: Vector2) -> Variant:
	if camera == null:
		return null
	return InputMath.ray_to_ground(
		camera.project_ray_origin(screen_position), camera.project_ray_normal(screen_position)
	)
