class_name RushAbility
extends HunterAbility
## A telegraphed straight-line rush (Brute charge): locks direction, shows a
## line, then dashes along it. Anything it hits is damaged and stunned. Walls
## stop it.

@export var wind_up: float = 0.9
## The aim tracks the target until this long before the rush, then locks.
@export var lock_time: float = 0.3
## Longest rush; it rushes a little past where it expects you to be.
@export var distance: float = 16.0
@export var overshoot: float = 3.0
@export var speed: float = 26.0
@export var width: float = 2.0
@export var damage: float = 45.0
@export var stun: float = 0.8
@export var recovery: float = 0.9
@export var lead: float = 0.3


func create_action(brain: HunterBrain) -> HunterAction:
	return Action.new(brain, self)


class Action:
	extends HunterAction

	enum Phase { WIND_UP, RUSHING, RECOVER }

	var ability: RushAbility
	var _phase: Phase = Phase.WIND_UP
	var _timer: float = 0.0
	var _direction: Vector3
	var _length: float = 16.0
	var _dash: DashMovement
	var _hit: Array[Targetable] = []

	func _init(p_brain: HunterBrain, p_ability: RushAbility) -> void:
		super(p_brain)
		ability = p_ability

	func start() -> void:
		enemy().movement.stop()
		_aim()
		brain.warning.show_line(enemy().global_position, _direction, _length, ability.width)
		_timer = ability.wind_up

	## Aims at where the target will be when the rush arrives.
	func _aim() -> void:
		var from: Vector3 = enemy().global_position
		var arrival: float = maxf(_timer, 0.0) + brain.distance_to_target() / ability.speed
		var point: Vector3 = brain.target.predicted_position(arrival) if brain.target else from
		var offset: Vector3 = Vector3(point.x - from.x, 0.0, point.z - from.z)
		if offset.length_squared() < 0.01:
			_direction = enemy().movement.get_facing()
			_length = ability.distance
		else:
			_direction = offset.normalized()
			_length = minf(offset.length() + ability.overshoot, ability.distance)
		enemy().movement.face_towards(_direction)

	func tick(delta: float) -> bool:
		match _phase:
			Phase.WIND_UP:
				_timer -= delta
				if _timer > ability.lock_time:
					_aim()
					brain.warning.show_line(
						enemy().global_position, _direction, _length, ability.width
					)
				brain.warning.set_progress(1.0 - _timer / ability.wind_up)
				if _timer <= 0.0:
					brain.warning.clear()
					_dash = DashMovement.new(_direction, _length, ability.speed, 0.15)
					enemy().movement.start_override(_dash)
					_phase = Phase.RUSHING
			Phase.RUSHING:
				_check_hits()
				if _dash.finished:
					_phase = Phase.RECOVER
					_timer = ability.recovery
			Phase.RECOVER:
				_timer -= delta
				return _timer <= 0.0
		return false

	func cancel() -> void:
		brain.warning.clear()
		if _dash != null:
			_dash.cancel()

	func _check_hits() -> void:
		var from: Vector3 = enemy().global_position
		var reach: float = ability.width * 0.5 + enemy().body_radius
		for target: Targetable in AttackUtils.player_targets(enemy().get_tree()):
			if target in _hit or target.flat_distance_to(from) > reach:
				continue
			_hit.append(target)
			AttackUtils.damage(
				target, enemy().scaled_damage(ability.damage), enemy().data.damage_type, enemy()
			)
			AttackUtils.apply_status(target, StunEffect.new(ability.stun, &"hunter_stun"))
