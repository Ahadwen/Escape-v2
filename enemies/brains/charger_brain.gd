class_name ChargerBrain
extends EnemyBrain
## Chase -> stop and telegraph a line -> dash along it (direction locked at
## the start of the telegraph, so it can be dodged) -> recover.

enum State { CHASE, TELEGRAPH, CHARGING, RECOVER }

var state: State = State.CHASE

var _data: ChargerEnemyData
var _timer: float = 0.0
var _charge_direction: Vector3 = Vector3.ZERO
var _dash: DashMovement
var _hit_targets: Array[Targetable] = []


func _init(p_data: ChargerEnemyData) -> void:
	_data = p_data


func think(delta: float) -> void:
	match state:
		State.CHASE:
			if target == null:
				wander(delta)
			elif distance_to_target() <= _data.charge_trigger_range:
				_begin_telegraph()
			else:
				chase(delta)
		State.TELEGRAPH:
			_timer -= delta
			if _timer <= 0.0:
				_begin_charge()
		State.CHARGING:
			hit_targets_in_radius(_data.hit_radius, _hit_targets)
			if _dash == null or _dash.finished:
				_end_charge()
		State.RECOVER:
			_timer -= delta
			if _timer <= 0.0:
				state = State.CHASE


func interrupt() -> void:
	super()
	_dash = null
	_timer = _data.recover_time
	state = State.RECOVER


func _begin_telegraph() -> void:
	enemy.movement.stop()
	# Lead the target a little; the line then stays locked so it can be dodged.
	_charge_direction = direction_to_predicted(_data.telegraph_time * 0.5)
	if _charge_direction == Vector3.ZERO:
		return
	enemy.movement.face_towards(_charge_direction)
	telegraph.show_direction(enemy.global_position, _charge_direction, _data.charge_distance)
	_timer = _data.telegraph_time
	state = State.TELEGRAPH


func _begin_charge() -> void:
	telegraph.clear()
	_hit_targets.clear()
	_dash = DashMovement.new(_charge_direction, _data.charge_distance, _data.charge_speed)
	enemy.movement.start_override(_dash)
	state = State.CHARGING


func _end_charge() -> void:
	_dash = null
	_timer = _data.recover_time
	state = State.RECOVER
