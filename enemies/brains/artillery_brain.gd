class_name ArtilleryBrain
extends EnemyBrain
## Keep far back; every cooldown, lob a GroundStrike at the target's predicted
## position. No line of sight needed (it's lobbed).

var _data: ArtilleryEnemyData
var _cooldown: float = 0.0


func _init(p_data: ArtilleryEnemyData) -> void:
	_data = p_data
	_cooldown = randf_range(0.8, 1.6)


func think(delta: float) -> void:
	_cooldown -= delta
	if target == null:
		wander(delta)
		return
	keep_distance(delta, _data.preferred_min, _data.preferred_max)
	if _cooldown <= 0.0 and distance_to_target() <= _data.fire_range:
		_fire()


func _fire() -> void:
	_cooldown = _data.attack_cooldown
	var point: Vector3 = target.predicted_position(_data.lead_time)
	var map: RID = enemy.get_world_3d().navigation_map
	point = NavigationServer3D.map_get_closest_point(map, point)
	enemy.movement.face_towards(point - enemy.global_position)
	var strike: GroundStrike = GroundStrike.new()
	strike.configure(
		point,
		_data.strike_radius,
		_data.strike_wind_up * DilationField.wind_up_scale_at(point),
		enemy.scaled_damage(_data.damage),
		_data.damage_type,
		enemy,
		_data.linger_duration,
		enemy.scaled_damage(_data.linger_damage),
		_data.linger_interval
	)
	enemy.get_parent().add_child(strike)
