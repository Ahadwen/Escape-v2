class_name LaserBrain
extends EnemyBrain
## Approach -> prime (thin locked line, stops at walls) -> fire beam -> cooldown.

enum State { APPROACH, PRIME, COOLDOWN }

const PRIME_LINE_WIDTH: float = 0.2

var state: State = State.APPROACH

var _data: LaserEnemyData
var _timer: float = 0.0
var _beam_from: Vector3
var _beam_to: Vector3
var _prime_line: AimIndicator


func _init(p_data: LaserEnemyData) -> void:
	_data = p_data


func _ready() -> void:
	super()
	_prime_line = AimIndicator.new()
	_prime_line.color = Color(1.0, 0.3, 0.9, 0.7)
	_prime_line.line_width = PRIME_LINE_WIDTH
	_prime_line.top_level = true
	add_child(_prime_line)


func think(delta: float) -> void:
	match state:
		State.APPROACH:
			if target == null:
				wander(delta)
			elif distance_to_target() <= _data.fire_range and has_line_of_sight_to_target():
				_begin_prime()
			else:
				chase(delta)
		State.PRIME:
			_timer -= delta
			if _timer <= 0.0:
				_fire()
		State.COOLDOWN:
			_timer -= delta
			if _timer <= 0.0:
				state = State.APPROACH


func interrupt() -> void:
	super()
	_prime_line.clear()
	_timer = _data.attack_cooldown * 0.5
	state = State.COOLDOWN


func _begin_prime() -> void:
	enemy.movement.stop()
	var direction: Vector3 = direction_to_predicted(_data.lead_time)
	if direction == Vector3.ZERO:
		return
	enemy.movement.face_towards(direction)
	_beam_from = enemy.attack_origin()
	var raised_from: Vector3 = _beam_from + Vector3.UP * AttackUtils.EYE_HEIGHT
	var raised_end: Vector3 = AttackUtils.ray_to_wall(
		enemy.get_world_3d(), raised_from, raised_from + direction * _data.beam_length
	)
	_beam_to = Vector3(raised_end.x, _beam_from.y, raised_end.z)
	var length: float = Vector2(_beam_to.x - _beam_from.x, _beam_to.z - _beam_from.z).length()
	_prime_line.show_direction(_beam_from, direction, length)
	_timer = _data.prime_time * DilationField.wind_up_scale_at(enemy.global_position)
	state = State.PRIME


func _fire() -> void:
	_prime_line.clear()
	var beam: LaserBeam = LaserBeam.new()
	beam.configure(
		_beam_from,
		_beam_to,
		_data.beam_half_width,
		enemy.scaled_damage(_data.damage),
		_data.damage_type,
		enemy
	)
	enemy.get_parent().add_child(beam)
	_timer = _data.attack_cooldown
	state = State.COOLDOWN
