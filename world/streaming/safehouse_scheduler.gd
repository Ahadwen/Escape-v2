class_name SafehouseScheduler
extends Node
## Opens a safehouse every so often (random interval) a good distance ahead
## of where the player has been heading. Only one is open at a time: when the
## next opens, the previous one closes. It's revealed as soon as it opens, so
## going for it (or not) is a choice.

signal opened(safehouse: Safehouse)
signal closed
signal entered(player: Player)

## Keep this clear of obstacles around a new safehouse.
const CLEAR_RADIUS: float = 3.5

var profile: TerrainProfile
var player: Node3D
var safehouse_scene: PackedScene

var _timer: float = 0.0
var _current: Safehouse
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func setup(p_profile: TerrainProfile, p_player: Node3D, p_scene: PackedScene, p_seed: int) -> void:
	profile = p_profile
	player = p_player
	safehouse_scene = p_scene
	_rng.seed = p_seed
	_timer = _next_interval()


func enabled() -> bool:
	return profile != null and profile.safehouse_interval_min > 0.0 and safehouse_scene != null


func time_until_next() -> float:
	return _timer


func _physics_process(delta: float) -> void:
	if not enabled() or player == null:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = _next_interval()
	_open()


func _next_interval() -> float:
	return _rng.randf_range(profile.safehouse_interval_min, profile.safehouse_interval_max)


func _open() -> void:
	var point: Variant = _pick_point()
	if point == null:
		_timer = 2.0
		return
	if is_instance_valid(_current):
		_current.queue_free()
		closed.emit()
	var at: Vector3 = point
	_clear_obstacles(at)
	_current = safehouse_scene.instantiate() as Safehouse
	_current.position = at
	_current.entered.connect(func(who: Player) -> void: entered.emit(who))
	add_child(_current)
	var discoverable: Discoverable = _current.get_node_or_null("Discoverable") as Discoverable
	if discoverable != null:
		discoverable.is_discovered = true
	opened.emit(_current)


## A point on the navmesh ahead of the player's recent heading.
func _pick_point() -> Variant:
	var origin: Vector3 = player.global_position
	var heading: Vector3 = _player_heading()
	var map: RID = player.get_world_3d().navigation_map
	for attempt: int in 10:
		var direction: Vector3
		if heading.length() > 1.0:
			var spread: float = deg_to_rad(profile.safehouse_spread_degrees)
			direction = heading.normalized().rotated(Vector3.UP, _rng.randf_range(-spread, spread))
		else:
			var angle: float = _rng.randf() * TAU
			direction = Vector3(cos(angle), 0.0, sin(angle))
		var distance: float = _rng.randf_range(
			profile.safehouse_distance_min, profile.safehouse_distance_max
		)
		var point: Vector3 = NavigationServer3D.map_get_closest_point(
			map, origin + direction * distance
		)
		var flat: float = Vector2(point.x - origin.x, point.z - origin.z).length()
		if flat >= profile.safehouse_distance_min * 0.6:
			return point
	return null


func _player_heading() -> Vector3:
	var targetable: Targetable = player.get_node_or_null("Targetable") as Targetable
	if targetable != null:
		return targetable.average_velocity
	return Vector3.ZERO


func _clear_obstacles(at: Vector3) -> void:
	for node: Node in get_tree().get_nodes_in_group(Obstacles.GROUP):
		var body: Node3D = node as Node3D
		if body == null:
			continue
		var offset: Vector2 = Vector2(body.global_position.x - at.x, body.global_position.z - at.z)
		if offset.length() < CLEAR_RADIUS + 3.0:
			Obstacles.destroy(body)
