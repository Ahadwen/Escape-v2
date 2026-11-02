class_name InputMath
extends RefCounted
## Pure helper functions shared by input schemes. No state, no nodes, so it is
## unit-tested directly.


## Converts a stick vector (x right, y down, as returned by Input.get_vector)
## into a flat world-space direction relative to the camera's view.
## The result has length 0..1.
static func stick_to_world(stick: Vector2, camera_basis: Basis) -> Vector3:
	var right: Vector3 = Vector3(camera_basis.x.x, 0.0, camera_basis.x.z)
	# Screen-up projected onto the ground. Use the view direction, falling back
	# to the camera's up vector when looking straight down.
	var forward: Vector3 = Vector3(-camera_basis.z.x, 0.0, -camera_basis.z.z)
	if forward.length_squared() < 0.000001:
		forward = Vector3(camera_basis.y.x, 0.0, camera_basis.y.z)
	if right.length_squared() < 0.000001 or forward.length_squared() < 0.000001:
		return Vector3.ZERO
	var world: Vector3 = right.normalized() * stick.x + forward.normalized() * -stick.y
	return world.limit_length(1.0)


## Intersects a ray with the horizontal ground plane at ground_height.
## Returns the hit point as a Vector3, or null if the ray misses.
static func ray_to_ground(
	origin: Vector3, direction: Vector3, ground_height: float = 0.0
) -> Variant:
	return Plane(Vector3.UP, ground_height).intersects_ray(origin, direction)


## Maps a virtual joystick knob offset to a 0..1 output with a rescaled
## deadzone, so output starts at 0 just outside the deadzone.
static func joystick_output(offset: Vector2, radius: float, deadzone: float) -> Vector2:
	if radius <= 0.0:
		return Vector2.ZERO
	var raw: Vector2 = (offset / radius).limit_length(1.0)
	var magnitude: float = raw.length()
	if magnitude <= deadzone:
		return Vector2.ZERO
	return raw / magnitude * inverse_lerp(deadzone, 1.0, magnitude)
