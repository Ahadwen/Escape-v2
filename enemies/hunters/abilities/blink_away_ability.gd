class_name BlinkAwayAbility
extends HunterAbility
## The Artillerist's escape: if you get close it drops what it's doing, flashes
## briefly and teleports away to a set distance. Set `interrupts` in data.

@export var tell_time: float = 0.25
@export var distance: float = 16.0


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
		var goal: Vector3 = brain.target.world_position() + away * ability.distance
		var map: RID = enemy().get_world_3d().navigation_map
		enemy().movement.teleport(NavigationServer3D.map_get_closest_point(map, goal), -away)
		return true

	func cancel() -> void:
		enemy().set_tell(false)
