class_name AmbushAbility
extends HunterAbility
## The Assassin: vanishes (a faint shimmer) and moves fast to a flank point
## slightly ahead of where you're heading, then reappears for a three-dash
## combo. Each dash has a brief line warning, is led at where you'll be, and
## carries it through and past you, so walking away doesn't work: sidestep as
## it locks. Then it backs off.

## Speed while getting into position, as a multiple of its pursuit speed.
@export var stalk_speed_multiplier: float = 1.7
@export var stalk_timeout: float = 5.0
## Flank point: this far ahead of you along your heading ...
@export var flank_ahead: float = 3.5
## ... and this far to its side.
@export var flank_side: float = 3.0
## Strikes once this close to you (or at the flank point).
@export var reveal_distance: float = 4.0
## Warning time per dash; it locks lock_time before going.
@export var strike_wind_up: float = 0.3
@export var strike_lock: float = 0.12
## Pause after each dash before the next warning.
@export var strike_gap: float = 0.12
## Each dash ends this far past where it expects you to be ...
@export var overshoot: float = 3.0
## ... within these lengths.
@export var dash_min: float = 5.0
@export var dash_max: float = 11.0
@export var dash_width: float = 1.4
@export var dash_speed: float = 30.0
@export var damage: float = 35.0
@export var retreat_time: float = 0.8


func create_action(brain: HunterBrain) -> HunterAction:
	return Action.new(brain, self)


## Where to set up: ahead of the target along its heading, off to `side`
## (+1 / -1). With no heading, beside the target on that side.
func flank_point(target_position: Vector3, heading: Vector3, side: float) -> Vector3:
	var forward: Vector3 = Vector3(heading.x, 0.0, heading.z)
	if forward.length() < 1.0:
		forward = Vector3.FORWARD
		return target_position + forward.cross(Vector3.UP) * flank_side * side
	forward = forward.normalized()
	var lateral: Vector3 = forward.cross(Vector3.UP)
	return target_position + forward * flank_ahead + lateral * flank_side * side


class Action:
	extends HunterAction

	enum Phase { STALK, WARN, DASH, GAP, RETREAT }

	const STRIKES: int = 3
	const STALK_REPATH: float = 0.2

	var ability: AmbushAbility
	var _phase: Phase = Phase.STALK
	var _timer: float = 0.0
	var _repath: float = 0.0
	var _side: float = 1.0
	var _strike: int = 0
	var _direction: Vector3 = Vector3.FORWARD
	var _length: float = 6.0
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
		# Flank on whichever side it's already on.
		var heading: Vector3 = brain.target.average_velocity
		var offset: Vector3 = enemy().global_position - brain.target.world_position()
		_side = 1.0 if heading.cross(Vector3.UP).dot(offset) >= 0.0 else -1.0
		enemy().set_cloaked(true)
		_timer = ability.stalk_timeout

	func tick(delta: float) -> bool:
		match _phase:
			Phase.STALK:
				_stalk(delta)
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

	func _stalk(delta: float) -> void:
		enemy().movement.speed_floor *= ability.stalk_speed_multiplier
		_timer -= delta
		_repath -= delta
		var point: Vector3 = ability.flank_point(
			brain.target.world_position(), brain.target.average_velocity, _side
		)
		if _repath <= 0.0:
			_repath = STALK_REPATH
			enemy().movement.move_to(point)
		var at_point: bool = (
			(
				Vector2(point.x - enemy().global_position.x, point.z - enemy().global_position.z)
				. length()
			)
			< 1.5
		)
		if brain.distance_to_target() <= ability.reveal_distance or at_point or _timer <= 0.0:
			enemy().set_cloaked(false)
			_warn()

	func _warn() -> void:
		enemy().movement.stop()
		_phase = Phase.WARN
		_timer = ability.strike_wind_up
		_aim()

	## Leads to where you'll be when the dash reaches you, and goes past.
	func _aim() -> void:
		var from: Vector3 = enemy().global_position
		var arrival: float = maxf(_timer, 0.0) + brain.distance_to_target() / ability.dash_speed
		var point: Vector3 = brain.target.predicted_position(arrival)
		var offset: Vector3 = Vector3(point.x - from.x, 0.0, point.z - from.z)
		if offset.length_squared() < 0.01:
			_direction = enemy().movement.get_facing()
			_length = ability.dash_min
		else:
			_direction = offset.normalized()
			_length = clampf(
				offset.length() + ability.overshoot, ability.dash_min, ability.dash_max
			)
		enemy().movement.face_towards(_direction)
		brain.warning.show_line(from, _direction, _length, ability.dash_width)

	func _begin_dash() -> void:
		brain.warning.clear()
		_hit.clear()
		_last_position = enemy().global_position
		_dash = DashMovement.new(_direction, _length, ability.dash_speed, 0.05)
		enemy().movement.start_override(_dash)
		_phase = Phase.DASH

	## Hits anyone the dash passes through this frame (once per dash).
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
