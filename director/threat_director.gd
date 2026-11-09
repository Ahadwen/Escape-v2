class_name ThreatDirector
extends Node
## Raises threat over the level and spawns enemies to match it, off-screen
## and near the player. Tracks the threat cost of enemies alive.

signal threat_changed(threat: float)

const GROUP: StringName = &"threat_director"
const SPAWN_ATTEMPTS: int = 12
const RETRY_DELAY: float = 0.5
const FAR_CHECK_INTERVAL: float = 1.0

@export var profile: ThreatProfile
@export var enemy_scene: PackedScene
@export var player: Node3D
## Used to keep spawns off-screen.
@export var camera: Camera3D

var elapsed: float = 0.0
var threat: float = 0.0
var running: bool = false
## The level's zone blend (variants replace shared enemies by chance).
var theme: LevelTheme

var _spawn_timer: float = 0.0

var _alive: Array[Enemy] = []
var _debug_index: int = 0
## Id of the last enemy to leave (not re-picked straight away).
var _last_departed: StringName = &""
var _far_check_timer: float = FAR_CHECK_INTERVAL
## The ambient supply (Shamblers): tracked apart from the hunt.
var _ambient: Array[Enemy] = []
var _ambient_timer: float = 0.0


func start(level: int = 0) -> void:
	profile = profile.duplicate()
	profile.level = level
	EnemyTime.reset()
	DilationField.clear()
	elapsed = 0.0
	threat = profile.threat_at(0.0)
	_spawn_timer = profile.initial_delay
	_ambient_timer = profile.initial_delay
	running = true
	threat_changed.emit(threat)


static func find(tree: SceneTree) -> ThreatDirector:
	return tree.get_first_node_in_group(GROUP) as ThreatDirector


func _enter_tree() -> void:
	add_to_group(GROUP)


## Stops spawning and the threat clock. Optionally despawns every enemy,
## including ones spawned by other enemies (e.g. mites).
func stop(despawn_all: bool = false) -> void:
	running = false
	if despawn_all:
		for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
			var enemy: Enemy = node as Enemy
			if enemy != null:
				enemy.despawn()
		_alive.clear()
		_ambient.clear()


## Debug builds: F2 spawns the next enemy type from the profile near the
## player, ignoring threat, budget and visibility.
func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not event.is_action_pressed(InputActions.DEBUG_SPAWN_ENEMY):
		return
	if profile.entries.is_empty() or player == null:
		return
	var entry: SpawnEntry = profile.entries[_debug_index % profile.entries.size()]
	_debug_index += 1
	var map: RID = player.get_world_3d().navigation_map
	var angle: float = randf() * TAU
	var guess: Vector3 = player.global_position + Vector3(cos(angle), 0.0, sin(angle)) * 12.0
	_spawn(entry, GroundNav.closest_point(map, guess))
	print("Debug spawn: %s" % entry.enemy.display_name)


## Hunters currently on the field (not the ambient Shamblers).
func hunter_count() -> int:
	return _alive_count()


## Ambient enemies (Shamblers) currently around.
func ambient_count() -> int:
	var count: int = 0
	for enemy: Enemy in _ambient:
		if is_instance_valid(enemy):
			count += 1
	return count


func alive_cost() -> float:
	var total: float = 0.0
	for enemy: Enemy in _alive:
		if is_instance_valid(enemy) and enemy.data != null:
			total += enemy.data.threat_cost
	return total


func _physics_process(delta: float) -> void:
	EnemyTime.tick(delta)
	if not running:
		return
	elapsed += delta
	var new_threat: float = profile.threat_at(elapsed)
	if not is_equal_approx(new_threat, threat):
		threat = new_threat
		threat_changed.emit(threat)
	_far_check_timer -= delta
	if _far_check_timer <= 0.0:
		_far_check_timer = FAR_CHECK_INTERVAL
		_despawn_far_enemies()
	_ambient_timer -= delta
	if _ambient_timer <= 0.0:
		_ambient_timer = profile.ambient_interval
		_top_up_ambient()
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = profile.spawn_interval_for(threat)
		if not _try_spawn():
			_spawn_timer = minf(_spawn_timer, RETRY_DELAY)


func _try_spawn() -> bool:
	var cap: int = profile.max_alive_for(threat)
	if cap > 0 and _alive_count() >= cap:
		return true
	var budget_left: float = profile.budget_for(threat) - alive_cost()
	var exclude: Array[StringName] = _alive_ids()
	if _last_departed != &"":
		exclude.append(_last_departed)
	var entry: SpawnEntry = profile.pick_entry(threat, budget_left, randf(), exclude)
	if entry == null and not exclude.is_empty():
		entry = profile.pick_entry(threat, budget_left, randf(), _alive_ids())
	if entry == null:
		# Budget full: not a failure, just wait for the next interval.
		return true
	var point: Variant = _find_spawn_point()
	if point == null:
		return false
	_spawn(entry, point)
	return true


func _spawn(entry: SpawnEntry, point: Vector3) -> void:
	var enemy: Enemy = _create(entry.enemy, point)
	enemy.despawned.connect(_on_enemy_despawned)
	add_child(enemy)
	_alive.append(enemy)


## Spawns one ambient enemy if there are fewer than the target.
func _top_up_ambient() -> void:
	for i: int in range(_ambient.size() - 1, -1, -1):
		if not is_instance_valid(_ambient[i]) or _ambient[i].is_despawning():
			_ambient.remove_at(i)
	if _ambient.size() >= profile.ambient_target_for(threat):
		return
	var point: Variant = _find_spawn_point()
	if point == null:
		return
	var enemy: Enemy = _create(profile.ambient_enemy, point)
	add_child(enemy)
	_ambient.append(enemy)


func _create(data: EnemyData, point: Vector3) -> Enemy:
	var enemy: Enemy = enemy_scene.instantiate() as Enemy
	enemy.data = theme.enemy_for(data, randf()) if theme != null else data
	enemy.damage_multiplier = profile.damage_multiplier_for(threat)
	enemy.speed_multiplier = profile.speed_multiplier_for(threat)
	enemy.position = point
	return enemy


func _find_spawn_point() -> Variant:
	if player == null:
		return null
	var map: RID = player.get_world_3d().navigation_map
	var origin: Vector3 = player.global_position
	var heading: Vector3 = Vector3.ZERO
	if player is CharacterBody3D:
		heading = (player as CharacterBody3D).velocity
	for i: int in SPAWN_ATTEMPTS:
		var angle: float = profile.spawn_angle(heading, randf(), randf())
		var distance: float = randf_range(profile.spawn_distance_min, profile.spawn_distance_max)
		var guess: Vector3 = origin + Vector3(cos(angle), 0.0, sin(angle)) * distance
		var point: Vector3 = GroundNav.closest_point(map, guess)
		var flat: float = Vector2(point.x - origin.x, point.z - origin.z).length()
		if flat < profile.spawn_distance_min * 0.75:
			continue
		if camera != null and camera.is_position_in_frustum(point + Vector3.UP):
			continue
		return point
	return null


func _despawn_far_enemies() -> void:
	if player == null:
		return
	var origin: Vector3 = player.global_position
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy: Enemy = node as Enemy
		if enemy == null or enemy.is_despawning():
			continue
		var offset: Vector3 = enemy.global_position - origin
		var distance: float = Vector2(offset.x, offset.z).length()
		var can_reenter: bool = profile.reentry_distance > 0.0 and enemy.data is HunterData
		if can_reenter and distance > profile.reentry_distance and not _on_screen(enemy):
			_reenter(enemy)
		elif distance > profile.despawn_distance:
			enemy.despawn()


## Moves a left-behind hunter to an off-screen spot ahead of the player.
func _reenter(enemy: Enemy) -> void:
	var point: Variant = _find_spawn_point()
	if point == null:
		return
	if enemy.brain != null:
		enemy.brain.interrupt()
	var at: Vector3 = point
	enemy.movement.teleport(at)


func _on_screen(enemy: Enemy) -> bool:
	return camera != null and camera.is_position_in_frustum(enemy.global_position + Vector3.UP)


func _alive_count() -> int:
	var count: int = 0
	for enemy: Enemy in _alive:
		if is_instance_valid(enemy):
			count += 1
	return count


func _alive_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for enemy: Enemy in _alive:
		if is_instance_valid(enemy) and enemy.data != null:
			ids.append(enemy.data.id)
	return ids


func _on_enemy_despawned(enemy: Enemy) -> void:
	_alive.erase(enemy)
	if enemy.data != null:
		_last_departed = enemy.data.id
