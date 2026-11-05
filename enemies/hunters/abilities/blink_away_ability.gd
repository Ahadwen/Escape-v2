class_name BlinkAwayAbility
extends HunterAbility
## The Artillerist's escape: if you get close it drops what it's doing, flashes
## briefly and teleports away to a set distance (ahead of you if you've been
## running one way). Set `interrupts` in data.

@export var tell_time: float = 0.25
@export var distance: float = 16.0
## If the target has been heading somewhere (average speed above this), it
## lands ahead of them instead, angled off to one side.
@export var ahead_min_speed: float = 3.0
@export var ahead_angle_degrees: float = 40.0


func create_action(brain: HunterBrain) -> HunterAction:
	return Action.new(brain, self)


class Action:
	extends HunterAction

	var ability: BlinkAwayAbility
	var _timer: float = 0.0
	var _done: bool = false

	func _init(p_brain: HunterBrain, p_ability: BlinkAwayAbility) -> void:
		super(p_brain)
		ability = p_ability

	func start() -> void:
		enemy().movement.stop()
		enemy().set_tell(true)
		_timer = ability.tell_time

	func tick(delta: float) -> bool:
		_timer -= delta
		if _timer > 0.0 or _done:
			return _done
		_done = true
		enemy().set_tell(false)
		if brain.target == null:
			return true
		var away: Vector3 = -brain.direction_to_target()
		if away == Vector3.ZERO:
			away = -enemy().movement.get_facing()
		var heading: Vector3 = brain.target.average_velocity
		if heading.length() > ability.ahead_min_speed:
			var turn: float = deg_to_rad(ability.ahead_angle_degrees) * signf(randf() - 0.5)
			away = heading.normalized().rotated(Vector3.UP, turn)
		var goal: Vector3 = brain.target.world_position() + away * ability.distance
		var map: RID = enemy().get_world_3d().navigation_map
		enemy().movement.teleport(GroundNav.closest_point(map, goal), -away)
		return true

	func cancel() -> void:
		enemy().set_tell(false)
