class_name HeadOffAbility
extends HunterAbility
## Repositions ahead of a target who keeps running one way (Artillerist
## relocates, Broodmother burrows). Uses the target's average heading over the
## last few seconds, not where it's facing. Fair: a circle marks where it
## will come up, and it flashes before vanishing.

## Only when the target has been heading somewhere at least this fast.
@export var min_heading_speed: float = 4.0
## Only when it's no further ahead of the target than this (along the heading).
@export var max_ahead_now: float = 4.0
## Comes up this far ahead of the target ...
@export var ahead_distance: float = 15.0
## ... offset to a random side by up to this much.
@export var side_spread: float = 6.0
## Never closer to the target than this.
@export var min_distance: float = 9.0
@export var tell_time: float = 0.6
@export var recovery: float = 0.3


func can_use(brain: HunterBrain) -> bool:
	if not super(brain):
		return false
	var heading: Vector3 = brain.target.average_velocity
	if heading.length() < min_heading_speed:
		return false
	var offset: Vector3 = brain.enemy.global_position - brain.target.world_position()
	offset.y = 0.0
	return offset.dot(heading.normalized()) <= max_ahead_now


## Where to come up: ahead along the heading, plus a side offset.
func destination(target_position: Vector3, heading: Vector3, side: float) -> Vector3:
	var forward: Vector3 = Vector3(heading.x, 0.0, heading.z).normalized()
	var lateral: Vector3 = forward.cross(Vector3.UP)
	var point: Vector3 = target_position + forward * ahead_distance + lateral * side
	var flat: Vector3 = Vector3(point.x - target_position.x, 0.0, point.z - target_position.z)
	if flat.length() < min_distance:
		point = target_position + flat.normalized() * min_distance
	return point


func create_action(brain: HunterBrain) -> HunterAction:
	return Action.new(brain, self)


class Action:
	extends HunterAction

	var ability: HeadOffAbility
	var _timer: float = 0.0
	var _moved: bool = false
	var _destination: Vector3

	func _init(p_brain: HunterBrain, p_ability: HeadOffAbility) -> void:
		super(p_brain)
		ability = p_ability

	func start() -> void:
		enemy().movement.stop()
		enemy().set_tell(true)
		_timer = ability.tell_time
		var side: float = randf_range(-ability.side_spread, ability.side_spread)
		# Aim for where they'll be when it arrives, along their heading.
		var heading: Vector3 = brain.target.average_velocity
		var arrival: Vector3 = brain.target.world_position() + heading * ability.tell_time
		var map: RID = enemy().get_world_3d().navigation_map
		_destination = NavigationServer3D.map_get_closest_point(
			map, ability.destination(arrival, heading, side)
		)
		brain.warning.show_circle(_destination, enemy().body_radius + 0.8)

	func tick(delta: float) -> bool:
		_timer -= delta
		if not _moved:
			brain.warning.set_progress(1.0 - _timer / ability.tell_time)
			if _timer <= 0.0:
				_arrive()
			return false
		return _timer <= 0.0

	func cancel() -> void:
		brain.warning.clear()
		enemy().set_tell(false)

	func _arrive() -> void:
		cancel()
		_moved = true
		_timer = ability.recovery
		var facing: Vector3 = Vector3.ZERO
		if brain.target != null:
			facing = brain.target.world_position() - _destination
		enemy().movement.teleport(_destination, facing)
