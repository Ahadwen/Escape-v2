class_name IsometricCamera
extends Camera3D
## Angled orthographic camera that smoothly follows a target.

@export var target: Node3D
## Degrees below horizontal. ~35 is classic isometric, higher is more top-down.
@export_range(10.0, 90.0) var pitch_degrees: float = 50.0
@export var yaw_degrees: float = 45.0
## How far back along the view direction the camera sits. Doesn't change the
## framing of an orthographic camera; just keeps the scene in front of it.
@export var distance: float = 30.0
## Orthographic view height in metres. Smaller = more zoomed in.
@export var view_size: float = 26.0
@export var follow_sharpness: float = 10.0

var _focus: Vector3 = Vector3.ZERO


func _ready() -> void:
	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = view_size
	rotation_degrees = Vector3(-pitch_degrees, yaw_degrees, 0.0)
	# Moved every rendered frame in _process, so it must not be interpolated.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if target != null:
		_focus = _target_position()
	_apply_position()


func _process(delta: float) -> void:
	if target == null:
		return
	var weight: float = 1.0 - exp(-follow_sharpness * delta)
	_focus = _focus.lerp(_target_position(), weight)
	_apply_position()


func _target_position() -> Vector3:
	return target.get_global_transform_interpolated().origin


func _apply_position() -> void:
	global_position = _focus + global_transform.basis.z * distance
