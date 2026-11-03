class_name BroodBrain
extends EnemyBrain
## Chase slowly; every interval, spawn mites around itself (up to a cap).

const ENEMY_SCENE_PATH: String = "res://enemies/enemy.tscn"

var _data: BroodEnemyData
var _timer: float = 0.0
var _minions: Array[Enemy] = []


func _init(p_data: BroodEnemyData) -> void:
	_data = p_data
	_timer = p_data.first_spawn_delay


func think(delta: float) -> void:
	if target == null:
		wander(delta)
	else:
		chase(delta)
	_timer -= delta
	if _timer <= 0.0:
		_timer = _data.spawn_interval
		if target != null:
			_spawn_wave()


func _spawn_wave() -> void:
	if _data.minion == null:
		return
	for i: int in range(_minions.size() - 1, -1, -1):
		if not is_instance_valid(_minions[i]):
			_minions.remove_at(i)
	# Loaded lazily (cached by ResourceLoader) to avoid a preload cycle with the
	# enemy scene.
	var scene: PackedScene = load(ENEMY_SCENE_PATH) as PackedScene
	var room: int = _data.max_minions - _minions.size()
	var map: RID = enemy.get_world_3d().navigation_map
	for i: int in mini(_data.spawn_count, room):
		var angle: float = randf() * TAU
		var offset: Vector3 = Vector3(cos(angle), 0.0, sin(angle)) * _data.spawn_radius
		var point: Vector3 = NavigationServer3D.map_get_closest_point(
			map, enemy.global_position + offset
		)
		var mite: Enemy = scene.instantiate() as Enemy
		mite.data = _data.minion
		mite.position = point
		enemy.get_parent().add_child(mite)
		_minions.append(mite)
