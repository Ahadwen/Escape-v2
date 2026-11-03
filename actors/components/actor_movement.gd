class_name ActorMovement
extends Node
## Moves a CharacterBody3D either along a navigation path to a point or in a
## steered direction, and turns its visual to face where it's going.
## Paths come from the NavigationServer; waypoints are judged reached by flat
## (XZ) distance, so the navmesh sitting slightly above the feet doesn't matter.
## A MovementOverride (dash, charge, knockback) takes priority while active.
## Shared by the player and (later) enemies.

signal arrived

enum Mode { IDLE, TO_POINT, DIRECTION }

## Flat distance at which a path waypoint counts as reached.
const WAYPOINT_REACHED_DISTANCE: float = 0.1

@export var body: CharacterBody3D
## Navigation layers used when pathing.
@export_flags_3d_navigation var navigation_layers: int = 1
## Node rotated to face movement. Rotating a child keeps collision unaffected.
@export var visual: Node3D
## Optional. If set, speed comes from its move_speed stat.
@export var stats: StatsComponent
## Fallback speed in metres per second when there's no StatsComponent.
@export var move_speed: float = 5.0
## How quickly the visual turns toward the movement direction.
@export var turn_sharpness: float = 16.0

var mode: Mode = Mode.IDLE

var _direction: Vector3 = Vector3.ZERO
var _path: PackedVector3Array = PackedVector3Array()
var _path_index: int = 0
var _override: MovementOverride
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


## Yaw that makes a node's forward (-Z) face the given flat direction.
static func yaw_for_direction(direction: Vector3) -> float:
	return atan2(-direction.x, -direction.z)


## Index of the first waypoint at or after `index` that is further than
## `reached_distance` from `position`, measured flat. Returns path.size() if
## all are reached.
static func next_waypoint_index(
	path: PackedVector3Array, index: int, position: Vector3, reached_distance: float
) -> int:
	var i: int = index
	while i < path.size():
		var offset: Vector2 = Vector2(path[i].x - position.x, path[i].z - position.z)
		if offset.length() > reached_distance:
			break
		i += 1
	return i


func move_to(point: Vector3) -> void:
	var map: RID = body.get_world_3d().navigation_map
	_path = NavigationServer3D.map_get_path(
		map, body.global_position, point, true, navigation_layers
	)
	_path_index = 0
	mode = Mode.TO_POINT if not _path.is_empty() else Mode.IDLE


## Instantly moves the actor (blinks). Cancels any path being followed, since
## it was planned from the old position. Optionally snaps facing.
func teleport(point: Vector3, face_direction: Vector3 = Vector3.ZERO) -> void:
	body.global_position = point
	body.velocity = Vector3.ZERO
	body.reset_physics_interpolation()
	if mode == Mode.TO_POINT:
		mode = Mode.IDLE
	face_towards(face_direction)
	if visual != null:
		visual.reset_physics_interpolation()


## Instantly turns the visual to face a flat direction (ignored if zero).
func face_towards(direction: Vector3) -> void:
	var flat: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if visual != null and flat.length_squared() > 0.0001:
		visual.rotation.y = yaw_for_direction(flat)


## Remaining waypoints on the current path (for debugging/UI).
func path_points_remaining() -> int:
	return maxi(_path.size() - _path_index, 0) if mode == Mode.TO_POINT else 0


## Steer in a world direction (length 0..1 scales speed). A zero vector stops
## steering, but doesn't cancel a path that is being followed.
func move_in_direction(direction: Vector3) -> void:
	if direction.length_squared() < 0.0001:
		_direction = Vector3.ZERO
		if mode == Mode.DIRECTION:
			mode = Mode.IDLE
		return
	_direction = Vector3(direction.x, 0.0, direction.z).limit_length(1.0)
	mode = Mode.DIRECTION


func stop() -> void:
	mode = Mode.IDLE


func current_speed() -> float:
	if stats != null and stats.block.has_base(StatIds.MOVE_SPEED):
		return stats.get_value(StatIds.MOVE_SPEED)
	return move_speed


## Flat world direction the actor is facing.
func get_facing() -> Vector3:
	var node: Node3D = visual if visual != null else body
	var forward: Vector3 = -node.global_basis.z
	forward.y = 0.0
	return forward.normalized() if forward.length_squared() > 0.0001 else Vector3.FORWARD


func has_override() -> bool:
	return _override != null


## Starts a movement override, replacing any current one. Cancels a path
## being followed; stick steering resumes when the override ends.
func start_override(movement_override: MovementOverride) -> void:
	if _override != null:
		_override.cancel()
	_override = movement_override
	if mode == Mode.TO_POINT:
		mode = Mode.IDLE


func _physics_process(delta: float) -> void:
	var desired: Vector3
	if _override != null:
		desired = _override.compute_velocity(delta)
	else:
		desired = _desired_velocity()
	body.velocity.x = desired.x
	body.velocity.z = desired.z
	if body.is_on_floor():
		body.velocity.y = 0.0
	else:
		body.velocity.y -= _gravity * delta
	body.move_and_slide()
	if _override != null:
		_override.after_move(body)
		if _override.finished:
			_override = null
	_face(desired, delta)


func _desired_velocity() -> Vector3:
	match mode:
		Mode.TO_POINT:
			var position: Vector3 = body.global_position
			_path_index = next_waypoint_index(
				_path, _path_index, position, WAYPOINT_REACHED_DISTANCE
			)
			if _path_index >= _path.size():
				mode = Mode.IDLE
				arrived.emit()
				return Vector3.ZERO
			var to_next: Vector3 = _path[_path_index] - position
			to_next.y = 0.0
			var distance: float = to_next.length()
			# Don't overshoot the waypoint on the last frame of approach.
			var speed: float = minf(current_speed(), distance / get_physics_process_delta_time())
			return to_next / distance * speed
		Mode.DIRECTION:
			return _direction * current_speed()
	return Vector3.ZERO


func _face(velocity: Vector3, delta: float) -> void:
	if visual == null or Vector2(velocity.x, velocity.z).length_squared() < 0.01:
		return
	var weight: float = 1.0 - exp(-turn_sharpness * delta)
	visual.rotation.y = lerp_angle(visual.rotation.y, yaw_for_direction(velocity), weight)
