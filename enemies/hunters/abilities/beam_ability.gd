class_name BeamAbility
extends HunterAbility
## The Artillerist's beam: a long, wide line charges up (tracking you, then
## locking), then fires straight through walls.

@export var charge_time: float = 1.1
@export var lock_time: float = 0.35
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
		_aim()

	func _aim() -> void:
		_direction = brain.direction_to_predicted(maxf(_timer, 0.0) * 0.5)
		if _direction == Vector3.ZERO:
			_direction = enemy().movement.get_facing()
		enemy().movement.face_towards(_direction)
		brain.warning.show_line(enemy().global_position, _direction, ability.length, ability.width)

	func tick(delta: float) -> bool:
		_timer -= delta
		if _fired:
			return _timer <= 0.0
		if _timer > ability.lock_time:
			_aim()
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
