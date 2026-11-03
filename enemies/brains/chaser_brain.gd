class_name ChaserBrain
extends EnemyBrain
## Chase (intercepting, flanking) -> wind up a short lunge (telegraph line,
## direction locked) -> lunge, hitting anything it touches -> recover.

enum State { CHASE, WIND_UP, LUNGING, RECOVER }

var state: State = State.CHASE

var _data: ChaserEnemyData
var _timer: float = 0.0
var _lunge_direction: Vector3 = Vector3.ZERO
var _lunge: DashMovement
var _hit_targets: Array[Targetable] = []


func _init(p_data: ChaserEnemyData) -> void:
	_data = p_data


func think(delta: float) -> void:
	match state:
		State.CHASE:
			if target == null:
				wander(delta)
			elif distance_to_target() <= _data.lunge_trigger_range:
				_begin_wind_up()
			else:
				chase(delta)
		State.WIND_UP:
			_timer -= delta
			if _timer <= 0.0:
				_begin_lunge()
		State.LUNGING:
			hit_targets_in_radius(_data.hit_radius, _hit_targets)
			if _lunge == null or _lunge.finished:
				_recover()
		State.RECOVER:
			_timer -= delta
			if _timer <= 0.0:
				state = State.CHASE


func interrupt() -> void:
	super()
	_lunge = null
	_timer = _data.attack_cooldown
	state = State.RECOVER


func _begin_wind_up() -> void:
	enemy.movement.stop()
	# Aim a little ahead, so moving in a straight line isn't a free dodge.
	_lunge_direction = direction_to_predicted(_data.wind_up)
	if _lunge_direction == Vector3.ZERO:
		return
	enemy.movement.face_towards(_lunge_direction)
	telegraph.show_direction(enemy.global_position, _lunge_direction, _data.lunge_distance)
	_timer = _data.wind_up
	state = State.WIND_UP


func _begin_lunge() -> void:
	telegraph.clear()
	_hit_targets.clear()
	_lunge = DashMovement.new(_lunge_direction, _data.lunge_distance, _data.lunge_speed)
	enemy.movement.start_override(_lunge)
	state = State.LUNGING


func _recover() -> void:
	_lunge = null
	_timer = _data.attack_cooldown
	state = State.RECOVER
