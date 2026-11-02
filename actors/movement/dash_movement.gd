class_name DashMovement
extends MovementOverride
## Moves a fixed distance in a straight line at a fixed speed. Stops early on
## hitting a wall.

var direction: Vector3
var speed: float
var remaining_distance: float


func _init(p_direction: Vector3, distance: float, p_speed: float) -> void:
	direction = Vector3(p_direction.x, 0.0, p_direction.z).normalized()
	remaining_distance = maxf(distance, 0.0)
	speed = p_speed


func compute_velocity(delta: float) -> Vector3:
	if remaining_distance <= 0.0 or delta <= 0.0 or direction == Vector3.ZERO:
		finished = true
		return Vector3.ZERO
	var step: float = minf(speed * delta, remaining_distance)
	remaining_distance -= step
	return direction * (step / delta)


func after_move(body: CharacterBody3D) -> void:
	if remaining_distance <= 0.001 or MovementOverride.hit_wall(body, direction):
		finished = true
