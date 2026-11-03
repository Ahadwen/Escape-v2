class_name SpinnerBrain
extends EnemyBrain
## Charge -> teeter (wobbling, slowing spin) -> charge again. Contact damage
## is handled by Enemy.

enum State { TEETER, CHARGING }

var state: State = State.TEETER

var _data: SpinnerEnemyData
var _timer: float = 0.6
var _dash: DashMovement
var _wobble_time: float = 0.0
var _spin: float = 0.0


func _init(p_data: SpinnerEnemyData) -> void:
	_data = p_data


func think(delta: float) -> void:
	match state:
		State.TEETER:
			_timer -= delta
			if _timer <= 0.0:
				if target == null:
					wander(delta)
				else:
					_begin_charge()
		State.CHARGING:
			if _dash == null or _dash.finished:
				_begin_teeter()


func interrupt() -> void:
	super()
	_dash = null
	_begin_teeter()


func _process(delta: float) -> void:
	if enemy == null or enemy.model == null:
		return
	var charging: bool = state == State.CHARGING
	var spin_rate: float = _data.spin_speed if charging else _data.spin_speed * 0.35
	_spin = wrapf(_spin + spin_rate * delta, -PI, PI)
	_wobble_time += delta
	var wobble: float = 0.0 if charging else 0.28
	enemy.model.rotation = Vector3(
		sin(_wobble_time * 9.0) * wobble, _spin, cos(_wobble_time * 7.0) * wobble
	)


func _begin_charge() -> void:
	var direction: Vector3 = direction_to_predicted(_data.lead_time)
	if direction == Vector3.ZERO:
		_timer = 0.3
		return
	var distance: float = minf(distance_to_target() + _data.overshoot, _data.max_charge_distance)
	_dash = DashMovement.new(direction, distance, _data.charge_speed)
	enemy.movement.start_override(_dash)
	state = State.CHARGING


func _begin_teeter() -> void:
	enemy.movement.stop()
	_timer = randf_range(_data.teeter_min, _data.teeter_max)
	state = State.TEETER
