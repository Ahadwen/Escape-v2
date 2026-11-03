class_name ChaserBrain
extends EnemyBrain
## Chase -> wind up (telegraph ring) -> hit if still in reach -> recover.

enum State { CHASE, WIND_UP, RECOVER }

var state: State = State.CHASE

var _data: ChaserEnemyData
var _timer: float = 0.0


func _init(p_data: ChaserEnemyData) -> void:
	_data = p_data


func think(delta: float) -> void:
	match state:
		State.CHASE:
			if target == null:
				wander(delta)
			elif distance_to_target() <= _data.attack_range:
				enemy.movement.stop()
				enemy.movement.face_towards(direction_to_target())
				telegraph.show_point(enemy.global_position, _data.attack_range)
				_timer = _data.wind_up
				state = State.WIND_UP
			else:
				chase(delta)
		State.WIND_UP:
			_timer -= delta
			if _timer <= 0.0:
				telegraph.clear()
				# A little leeway so a hit that "looked" like it connected does.
				if target != null and distance_to_target() <= _data.attack_range + 0.4:
					deal_damage(target)
				_timer = _data.attack_cooldown
				state = State.RECOVER
		State.RECOVER:
			_timer -= delta
			if _timer <= 0.0:
				state = State.CHASE


func interrupt() -> void:
	super()
	state = State.CHASE
