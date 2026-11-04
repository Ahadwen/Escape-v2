class_name AmbushAbility
extends HunterAbility
## The Assassin: vanishes (a faint shimmer) and closes in faster, reappears
## next to you and performs a three-strike sequence (each strike has its own
## short warning: cone, lunge, cone), then backs off.

@export var stalk_speed_multiplier: float = 1.25
@export var stalk_timeout: float = 4.0
## Reappears once this close.
@export var reveal_distance: float = 2.5
## Strikes close in during their wind-up (until they lock), at this multiple
## of its pursuit speed, so stepping away isn't enough on its own.
@export var advance_speed_ratio: float = 1.4
@export var strike_wind_up: float = 0.4
@export var strike_lock: float = 0.12
@export var strike_gap: float = 0.12
@export var cone_radius: float = 2.6
@export var cone_angle: float = 100.0
@export var lunge_length: float = 5.0
@export var lunge_width: float = 1.4
@export var lunge_speed: float = 22.0
@export var damage: float = 45.0
@export var retreat_time: float = 1.0


func create_action(brain: HunterBrain) -> HunterAction:
	return Action.new(brain, self)


class Action:
	extends HunterAction

	enum Phase { STALK, STRIKE, GAP, RETREAT }

	const STRIKES: int = 3

	var ability: AmbushAbility
	var _phase: Phase = Phase.STALK
	var _timer: float = 0.0
	var _strike: int = 0
	var _direction: Vector3 = Vector3.FORWARD
	var _dash: DashMovement

	func _init(p_brain: HunterBrain, p_ability: AmbushAbility) -> void:
		super(p_brain)
		ability = p_ability

	func start() -> void:
		if brain.distance_to_target() <= ability.reveal_distance:
			_begin_strike()
			return
		enemy().set_cloaked(true)
		_timer = ability.stalk_timeout

	func tick(delta: float) -> bool:
		match _phase:
			Phase.STALK:
				enemy().movement.speed_floor *= ability.stalk_speed_multiplier
				brain.chase(delta)
				_timer -= delta
				if brain.distance_to_target() <= ability.reveal_distance or _timer <= 0.0:
					enemy().set_cloaked(false)
					_begin_strike()
			Phase.STRIKE:
				_timer -= delta
				if _timer > ability.strike_lock:
					_aim()
					enemy().movement.speed_floor *= ability.advance_speed_ratio
					enemy().movement.move_in_direction(_direction)
				else:
					enemy().movement.stop()
				brain.warning.set_progress(1.0 - _timer / ability.strike_wind_up)
				if _timer <= 0.0:
					_hit()
			Phase.GAP:
				_timer -= delta
				if _timer <= 0.0 and (_dash == null or _dash.finished):
					if _strike < STRIKES:
						_begin_strike()
					else:
						_retreat()
			Phase.RETREAT:
				_timer -= delta
				return _timer <= 0.0
		return false

	func cancel() -> void:
		brain.warning.clear()
		enemy().set_cloaked(false)
		if _dash != null:
			_dash.cancel()

	func _is_lunge() -> bool:
		return _strike == 1

	func _begin_strike() -> void:
		enemy().movement.stop()
		_phase = Phase.STRIKE
		_timer = ability.strike_wind_up
		_aim()

	func _aim() -> void:
		_direction = brain.direction_to_predicted(0.15)
		if _direction == Vector3.ZERO:
			_direction = enemy().movement.get_facing()
		enemy().movement.face_towards(_direction)
		var from: Vector3 = enemy().global_position
		if _is_lunge():
			brain.warning.show_line(from, _direction, ability.lunge_length, ability.lunge_width)
		else:
			brain.warning.show_cone(from, _direction, ability.cone_radius, ability.cone_angle)

	func _hit() -> void:
		brain.warning.clear()
		var from: Vector3 = enemy().global_position
		var amount: float = enemy().scaled_damage(ability.damage)
		for target: Targetable in AttackUtils.player_targets(enemy().get_tree()):
			var at: Vector3 = target.world_position()
			var hit: bool
			if _is_lunge():
				var to: Vector3 = from + _direction * ability.lunge_length
				var near: float = AttackUtils.point_segment_distance_flat(at, from, to)
				hit = near <= ability.lunge_width * 0.5 + 0.4
			else:
				hit = AttackUtils.in_cone(
					from, _direction, ability.cone_radius + 0.4, ability.cone_angle, at
				)
			if hit:
				AttackUtils.damage(target, amount, enemy().data.damage_type, enemy())
		if _is_lunge():
			_dash = DashMovement.new(_direction, ability.lunge_length, ability.lunge_speed, 0.1)
			enemy().movement.start_override(_dash)
		_strike += 1
		_phase = Phase.GAP
		_timer = ability.strike_gap

	func _retreat() -> void:
		var away: Vector3 = -brain.direction_to_target()
		enemy().movement.move_to(enemy().global_position + away * 8.0)
		_phase = Phase.RETREAT
		_timer = ability.retreat_time
