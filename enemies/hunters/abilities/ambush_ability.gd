class_name AmbushAbility
extends HunterAbility
## The Assassin: vanishes (a faint shimmer) and closes in, reappears near you
## and performs three dash strikes. Each strike shows a brief line warning
## that locks in place, then it dashes straight along it: step off the line.
## Then it backs off.

@export var stalk_speed_multiplier: float = 1.1
@export var stalk_timeout: float = 4.0
## Reappears once this close.
@export var reveal_distance: float = 4.5
## Warning time per strike; it locks lock_time before the dash.
@export var strike_wind_up: float = 0.45
@export var strike_lock: float = 0.25
## Pause after each dash before the next warning.
@export var strike_gap: float = 0.3
@export var dash_length: float = 6.0
@export var dash_width: float = 1.4
@export var dash_speed: float = 20.0
@export var damage: float = 35.0
@export var retreat_time: float = 1.0


func create_action(brain: HunterBrain) -> HunterAction:
	return Action.new(brain, self)


class Action:
	extends HunterAction

	enum Phase { STALK, WARN, DASH, GAP, RETREAT }

	const STRIKES: int = 3

	var ability: AmbushAbility
	var _phase: Phase = Phase.STALK
	var _timer: float = 0.0
	var _strike: int = 0
	var _direction: Vector3 = Vector3.FORWARD
	var _dash: DashMovement
	var _hit: Array[Targetable] = []
	var _last_position: Vector3

	func _init(p_brain: HunterBrain, p_ability: AmbushAbility) -> void:
		super(p_brain)
		ability = p_ability

	func start() -> void:
		if brain.distance_to_target() <= ability.reveal_distance:
			_warn()
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
					_warn()
			Phase.WARN:
				_timer -= delta
				if _timer > ability.strike_lock:
					_aim()
				brain.warning.set_progress(1.0 - _timer / ability.strike_wind_up)
				if _timer <= 0.0:
					_begin_dash()
			Phase.DASH:
				_check_hits()
				if _dash.finished:
					_strike += 1
					_phase = Phase.GAP
					_timer = ability.strike_gap
			Phase.GAP:
				_timer -= delta
				if _timer <= 0.0:
					if _strike < STRIKES:
						_warn()
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

	func _warn() -> void:
		enemy().movement.stop()
		_phase = Phase.WARN
		_timer = ability.strike_wind_up
		_aim()

	## Aims at where you are now (no lead), so a sidestep dodges it.
	func _aim() -> void:
		_direction = brain.direction_to_target()
		if _direction == Vector3.ZERO:
			_direction = enemy().movement.get_facing()
		enemy().movement.face_towards(_direction)
		brain.warning.show_line(
			enemy().global_position, _direction, ability.dash_length, ability.dash_width
		)

	func _begin_dash() -> void:
		brain.warning.clear()
		_hit.clear()
		_last_position = enemy().global_position
		_dash = DashMovement.new(_direction, ability.dash_length, ability.dash_speed, 0.1)
		enemy().movement.start_override(_dash)
		_phase = Phase.DASH

	## Hits anyone the dash passes through this frame (once per strike).
	func _check_hits() -> void:
		var now: Vector3 = enemy().global_position
		var reach: float = ability.dash_width * 0.5 + 0.4
		for target: Targetable in AttackUtils.player_targets(enemy().get_tree()):
			if target in _hit or AttackUtils.is_phased(target):
				continue
			var near: float = AttackUtils.point_segment_distance_flat(
				target.world_position(), _last_position, now
			)
			if near <= reach:
				_hit.append(target)
				AttackUtils.damage(
					target, enemy().scaled_damage(ability.damage), enemy().data.damage_type, enemy()
				)
		_last_position = now

	func _retreat() -> void:
		var away: Vector3 = -brain.direction_to_target()
		enemy().movement.move_to(enemy().global_position + away * 8.0)
		_phase = Phase.RETREAT
		_timer = ability.retreat_time
