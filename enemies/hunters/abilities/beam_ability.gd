class_name BeamAbility
extends HunterAbility
## The Artillerist's beam: a long, wide line charges up, then fires straight
## through walls. While charging it sweeps (limited turn rate) toward where
## your recent heading will take you when it fires, then locks in place
## lock_time before firing: the last stretch is your window to step out.

@export var charge_time: float = 1.1
@export var lock_time: float = 0.5
## How fast the line can sweep while tracking (degrees per second).
@export var turn_rate_degrees: float = 360.0
@export var length: float = 30.0
@export var width: float = 2.4
@export var damage: float = 80.0
@export var recovery: float = 0.5
@export var color: Color = Color(1.0, 0.3, 0.9)


func create_action(brain: HunterBrain) -> HunterAction:
	return Action.new(brain, self)


class Action:
	extends HunterAction

	var ability: BeamAbility
	var _timer: float = 0.0
	var _fired: bool = false
	var _direction: Vector3 = Vector3.FORWARD

	func _init(p_brain: HunterBrain, p_ability: BeamAbility) -> void:
		super(p_brain)
		ability = p_ability

	func start() -> void:
		enemy().movement.stop()
		_timer = ability.charge_time
		_direction = _wanted_direction()
		_show()

	## Where it wants to point: your average heading carried forward to the
	## moment it fires (smooth, so a jink doesn't swing it).
	func _wanted_direction() -> Vector3:
		if brain.target == null:
			return _direction
		var lead: float = maxf(_timer, 0.0)
		var point: Vector3 = brain.target.world_position() + brain.target.average_velocity * lead
		var offset: Vector3 = point - enemy().global_position
		offset.y = 0.0
		return offset.normalized() if offset.length_squared() > 0.01 else _direction

	## Sweeps toward the wanted direction at the limited turn rate.
	func _track(delta: float) -> void:
		var wanted: Vector3 = _wanted_direction()
		var angle: float = _direction.signed_angle_to(wanted, Vector3.UP)
		var step: float = deg_to_rad(ability.turn_rate_degrees) * delta
		_direction = _direction.rotated(Vector3.UP, clampf(angle, -step, step)).normalized()
		_show()

	func _show() -> void:
		enemy().movement.face_towards(_direction)
		brain.warning.show_line(enemy().global_position, _direction, ability.length, ability.width)

	func tick(delta: float) -> bool:
		_timer -= delta
		if _fired:
			return _timer <= 0.0
		if _timer > ability.lock_time:
			_track(delta)
		brain.warning.set_progress(1.0 - _timer / ability.charge_time)
		if _timer <= 0.0:
			_fire()
		return false

	func cancel() -> void:
		brain.warning.clear()

	func _fire() -> void:
		brain.warning.clear()
		_fired = true
		_timer = ability.recovery
		var from: Vector3 = enemy().global_position
		var beam: LaserBeam = LaserBeam.new()
		beam.color = ability.color
		beam.configure(
			from,
			from + _direction * ability.length,
			ability.width * 0.5,
			enemy().scaled_damage(ability.damage),
			enemy().data.damage_type,
			enemy()
		)
		spawn_in_world(beam)
