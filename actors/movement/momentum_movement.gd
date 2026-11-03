class_name MomentumMovement
extends MovementOverride
## Accelerates, cruises while steering with a limited turn rate, then
## decelerates and coasts to a stop (Spinner's zoom). Walls stop it.

var direction: Vector3
var speed: float
var max_speed: float
var acceleration: float
var deceleration: float
## Radians per second.
var turn_rate: float
## Seconds of accelerating/cruising before slowing down.
var drive_time: float
## Where to steer. Zero = straight on.
var steer_direction: Vector3 = Vector3.ZERO

var _time: float = 0.0


func _init(
	p_direction: Vector3,
	start_speed: float,
	p_max_speed: float,
	p_acceleration: float,
	p_deceleration: float,
	p_turn_rate: float,
	p_drive_time: float
) -> void:
	direction = Vector3(p_direction.x, 0.0, p_direction.z).normalized()
	speed = start_speed
	max_speed = p_max_speed
	acceleration = p_acceleration
	deceleration = p_deceleration
	turn_rate = p_turn_rate
	drive_time = p_drive_time


func is_driving() -> bool:
	return _time < drive_time


func compute_velocity(delta: float) -> Vector3:
	_time += delta
	if direction == Vector3.ZERO:
		finished = true
		return Vector3.ZERO
	if is_driving():
		speed = minf(speed + acceleration * delta, max_speed)
		_steer(delta)
	else:
		speed = maxf(speed - deceleration * delta, 0.0)
		if speed <= 0.5:
			finished = true
			return Vector3.ZERO
	return direction * speed


func after_move(body: CharacterBody3D) -> void:
	if MovementOverride.hit_wall(body, direction):
		finished = true


func _steer(delta: float) -> void:
	var target: Vector3 = Vector3(steer_direction.x, 0.0, steer_direction.z)
	if target.length_squared() < 0.0001:
		return
	var angle: float = direction.signed_angle_to(target.normalized(), Vector3.UP)
	var step: float = turn_rate * delta
	direction = direction.rotated(Vector3.UP, clampf(angle, -step, step)).normalized()
