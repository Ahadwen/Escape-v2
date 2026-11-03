class_name BlinkLanding
extends RefCounted
## Works out where a blink lands. Blinks pass over walls; if the aimed spot
## isn't walkable, land on whichever walkable side of the obstacle (before or
## beyond it, along the blink line) is closer to the aimed spot.


## Returns the landing point (Vector3) or null if nowhere along the line is
## walkable. is_walkable: func(point: Vector3) -> bool.
static func find(
	origin: Vector3,
	direction: Vector3,
	distance: float,
	is_walkable: Callable,
	step: float = 0.1,
	max_overshoot: float = 3.0
) -> Variant:
	var dir: Vector3 = Vector3(direction.x, 0.0, direction.z).normalized()
	var target: Vector3 = origin + dir * distance
	if is_walkable.call(target):
		return target

	var steps_back: int = int(distance / step)
	var back_gap: float = INF
	var back_point: Vector3 = origin
	for i: int in range(1, steps_back + 1):
		var point: Vector3 = target - dir * (step * i)
		if is_walkable.call(point):
			back_point = point
			back_gap = step * i
			break

	var steps_forward: int = int(max_overshoot / step)
	var forward_gap: float = INF
	var forward_point: Vector3 = origin
	for i: int in range(1, steps_forward + 1):
		var gap: float = step * i
		if gap >= back_gap:
			break
		var point: Vector3 = target + dir * gap
		if is_walkable.call(point):
			forward_point = point
			forward_gap = gap
			break

	if forward_gap < back_gap:
		return forward_point
	if back_gap < INF:
		return back_point
	return null
