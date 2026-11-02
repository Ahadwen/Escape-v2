class_name ChargeMovement
extends MovementOverride
## Charges forward, accelerating, steerable with a limited turn rate. Ends on
## hitting a wall or when time runs out.

## Emitted when the charge ends by hitting something (not by timing out).
signal impacted(position: Vector3)

var direction: Vector3
var speed: float
var max_speed: float
var acceleration: float
## Radians per second.
var turn_rate: float
var remaining_time: float
## Where the player is steering. Zero means "keep going straight".
var steer_direction: Vector3 = Vector3.ZERO


func _init(
	p_direction: Vector3,
	start_speed: float,
	p_max_speed: float,
	p_acceleration: float,
	p_turn_rate: float,
	duration: float
) -> void:
	direction = Vector3(p_direction.x, 0.0, p_direction.z).normalized()
	speed = start_speed
	max_speed = p_max_speed
	acceleration = p_acceleration
	turn_rate = p_turn_rate
	remaining_time = duration


func compute_velocity(delta: float) -> Vector3:
	remaining_time -= delta
	if remaining_time <= 0.0 or direction == Vector3.ZERO:
		finished = true
		return Vector3.ZERO
	_steer(delta)
	speed = minf(speed + acceleration * delta, max_speed)
	return direction * speed


func after_move(body: CharacterBody3D) -> void:
	if MovementOverride.hit_wall(body, direction):
		impacted.emit(body.global_position)
		finished = true


func _steer(delta: float) -> void:
	var target: Vector3 = Vector3(steer_direction.x, 0.0, steer_direction.z)
	if target.length_squared() < 0.0001:
		return
	var angle: float = direction.signed_angle_to(target.normalized(), Vector3.UP)
	var max_step: float = turn_rate * delta
	direction = direction.rotated(Vector3.UP, clampf(angle, -max_step, max_step)).normalized()
