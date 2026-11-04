class_name MomentumMovement
extends MovementOverride
## Accelerates, cruises while steering with a limited turn rate, then
## decelerates and coasts to a stop (Spinner's zoom, Brute's charge).
## What a wall does depends on wall_mode: stop it, deflect it along the wall,
## or (SMASH) report the obstacle so the caller can destroy it and keep going.

## Emitted (SMASH mode) for each destructible obstacle it runs into.
signal hit_obstacle(body: Node3D)

enum WallMode { STOP, SLIDE, SMASH }

## Speed kept after deflecting off a wall (SLIDE).
const SLIDE_SPEED_KEPT: float = 0.75
## Speed kept after smashing through an obstacle (SMASH).
const SMASH_SPEED_KEPT: float = 0.85

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
var wall_mode: WallMode = WallMode.STOP

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


## Stops accelerating and steering; it slows down and coasts to a stop.
func stop_driving() -> void:
	drive_time = minf(drive_time, _time)


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
	match wall_mode:
		WallMode.STOP:
			if MovementOverride.hit_wall(body, direction):
				finished = true
		WallMode.SLIDE:
			_slide_along_walls(body)
		WallMode.SMASH:
			_smash_obstacles(body)


## Turns the direction to run along a wall it hit head-on, losing some speed.
func _slide_along_walls(body: CharacterBody3D) -> void:
	for i: int in body.get_slide_collision_count():
		var normal: Vector3 = body.get_slide_collision(i).get_normal()
		normal.y = 0.0
		if normal.length_squared() < 0.01 or normal.normalized().dot(direction) > -0.3:
			continue
		normal = normal.normalized()
		var along: Vector3 = direction - normal * direction.dot(normal)
		if along.length_squared() < 0.01:
			# Dead on: pick the side the steering wants.
			along = normal.cross(Vector3.UP)
			if along.dot(steer_direction) < 0.0:
				along = -along
		direction = along.normalized()
		speed *= SLIDE_SPEED_KEPT


func _smash_obstacles(body: CharacterBody3D) -> void:
	for i: int in body.get_slide_collision_count():
		var collision: KinematicCollision3D = body.get_slide_collision(i)
		if collision.get_normal().y >= 0.5:
			continue
		var collider: Node3D = collision.get_collider() as Node3D
		if collider != null and Obstacles.is_destructible(collider):
			hit_obstacle.emit(collider)
			speed *= SMASH_SPEED_KEPT
		elif collider is StaticBody3D and collision.get_normal().dot(direction) < -0.5:
			finished = true


func _steer(delta: float) -> void:
	var target: Vector3 = Vector3(steer_direction.x, 0.0, steer_direction.z)
	if target.length_squared() < 0.0001:
		return
	var angle: float = direction.signed_angle_to(target.normalized(), Vector3.UP)
	var step: float = turn_rate * delta
	direction = direction.rotated(Vector3.UP, clampf(angle, -step, step)).normalized()
