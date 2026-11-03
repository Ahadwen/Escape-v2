class_name GunnerBrain
extends EnemyBrain
## Keep range -> aim (short line) -> fire a projectile -> cooldown.

enum State { POSITION, AIM }

var state: State = State.POSITION

var _data: GunnerEnemyData
var _cooldown: float = 0.0
var _timer: float = 0.0
var _aim_direction: Vector3 = Vector3.ZERO


func _init(p_data: GunnerEnemyData) -> void:
	_data = p_data
	_cooldown = randf_range(0.4, 1.0)


func think(delta: float) -> void:
	_cooldown -= delta
	if target == null:
		wander(delta)
		return
	match state:
		State.POSITION:
			keep_distance(delta, _data.preferred_min, _data.preferred_max)
			var in_range: bool = distance_to_target() <= _data.fire_range
			if _cooldown <= 0.0 and in_range and has_line_of_sight_to_target():
				_begin_aim()
		State.AIM:
			_timer -= delta
			if _timer <= 0.0:
				_fire()


func interrupt() -> void:
	super()
	state = State.POSITION


func _begin_aim() -> void:
	enemy.movement.stop()
	var lead: float = distance_to_target() / _data.projectile_speed * 0.6
	_aim_direction = direction_to_predicted(lead + _data.aim_time)
	enemy.movement.face_towards(_aim_direction)
	telegraph.show_direction(enemy.global_position, _aim_direction, 2.5)
	_timer = _data.aim_time * DilationField.wind_up_scale_at(enemy.global_position)
	state = State.AIM


func _fire() -> void:
	telegraph.clear()
	if _data.flame_cone:
		var cone: FlameCone = FlameCone.new()
		cone.configure(
			enemy.attack_origin(),
			_aim_direction,
			enemy.scaled_damage(_data.damage),
			enemy,
			_data.fire_range + 2.0
		)
		enemy.get_parent().add_child(cone)
		_cooldown = _data.attack_cooldown
		state = State.POSITION
		return
	var shot: Projectile = Projectile.new()
	shot.configure(
		enemy.attack_origin(),
		_aim_direction,
		_data.projectile_speed,
		enemy.scaled_damage(_data.damage),
		_data.damage_type,
		enemy,
		_data.projectile_radius
	)
	enemy.get_parent().add_child(shot)
	_cooldown = _data.attack_cooldown
	state = State.POSITION
