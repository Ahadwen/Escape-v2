class_name GroundNav
extends RefCounted
## Navigation lookups that stay on the ground. The navmesh also has small
## walkable patches on top of obstacles (they're unreachable by walking, but
## "nearest navmesh point" can pick them), so anything placed or teleported
## by nearest point goes through here instead. Levels are flat: ground is
## anything near the height you ask from.

## How far above the asked-for height a point can be and still be ground.
const MAX_STEP: float = 0.5
## Rings searched around the point when its nearest navmesh point is on top
## of something.
const SEARCH_RADII: Array[float] = [1.0, 2.0, 3.0, 4.5, 6.0]
const SEARCH_DIRECTIONS: int = 8


## True if `point` is a navmesh point at ground level relative to `ground_y`.
static func is_ground(point: Vector3, ground_y: float) -> bool:
	return absf(point.y - ground_y) <= MAX_STEP


## The nearest ground-level navmesh point to `point` (searching outward if
## the nearest one is on an obstacle). Falls back to the plain nearest point.
static func closest_point(map: RID, point: Vector3) -> Vector3:
	var nearest: Vector3 = NavigationServer3D.map_get_closest_point(map, point)
	if is_ground(nearest, point.y):
		return nearest
	for radius: float in SEARCH_RADII:
		for i: int in SEARCH_DIRECTIONS:
			var angle: float = TAU * i / SEARCH_DIRECTIONS
			var probe: Vector3 = point + Vector3(cos(angle), 0.0, sin(angle)) * radius
			var candidate: Vector3 = NavigationServer3D.map_get_closest_point(map, probe)
			if is_ground(candidate, point.y):
				return candidate
	return nearest
