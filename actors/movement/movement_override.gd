class_name MovementOverride
extends RefCounted
## Temporarily takes over an actor's movement (dashes, charges, knockbacks).
## While one is active, ActorMovement ignores normal move orders.

## Emitted once, when the override ends for any reason.
signal ended

var finished: bool = false:
	set(value):
		if value and not finished:
			finished = value
			ended.emit()


## Velocity to apply this physics frame (horizontal components are used).
func compute_velocity(_delta: float) -> Vector3:
	return Vector3.ZERO


## Called after move_and_slide, e.g. to check collisions.
func after_move(_body: CharacterBody3D) -> void:
	pass


func cancel() -> void:
	finished = true


## True if the last move_and_slide hit a wall roughly head-on.
static func hit_wall(body: CharacterBody3D, direction: Vector3) -> bool:
	for i: int in body.get_slide_collision_count():
		var normal: Vector3 = body.get_slide_collision(i).get_normal()
		if normal.y < 0.5 and normal.dot(direction) < -0.5:
			return true
	return false
