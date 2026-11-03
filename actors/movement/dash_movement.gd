class_name DashMovement
extends MovementOverride
## Moves a fixed distance in a straight line at a fixed speed. Stops early on
## hitting a wall.

var direction: Vector3
var speed: float
var remaining_distance: float
var total_distance: float
## Over this final fraction of the distance, speed eases down to
## decay_min_ratio of full speed. 0 = constant speed.
var decay_fraction: float = 0.0
var decay_min_ratio: float = 0.25


func _init(
	p_direction: Vector3,
	distance: float,
	p_speed: float,
	p_decay_fraction: float = 0.0,
	p_decay_min_ratio: float = 0.25
) -> void:
	direction = Vector3(p_direction.x, 0.0, p_direction.z).normalized()
	remaining_distance = maxf(distance, 0.0)
	total_distance = remaining_distance
	speed = p_speed
	decay_fraction = clampf(p_decay_fraction, 0.0, 1.0)
	decay_min_ratio = clampf(p_decay_min_ratio, 0.05, 1.0)


## Speed at the current point of the dash (pure, for testing).
func current_speed() -> float:
	if decay_fraction <= 0.0 or total_distance <= 0.0:
		return speed
	var decay_length: float = total_distance * decay_fraction
	if remaining_distance >= decay_length:
		return speed
	return speed * lerpf(decay_min_ratio, 1.0, remaining_distance / decay_length)


func compute_velocity(delta: float) -> Vector3:
	if remaining_distance <= 0.0 or delta <= 0.0 or direction == Vector3.ZERO:
		finished = true
		return Vector3.ZERO
	var step: float = minf(current_speed() * delta, remaining_distance)
	remaining_distance -= step
	return direction * (step / delta)


func after_move(body: CharacterBody3D) -> void:
	if remaining_distance <= 0.001 or MovementOverride.hit_wall(body, direction):
		finished = true
