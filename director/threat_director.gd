class_name ThreatDirector
extends Node
## Raises threat over the level and spawns enemies to match it, off-screen
## and near the player. Tracks the threat cost of enemies alive.

signal threat_changed(threat: float)

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

var _spawn_timer: float = 0.0
var _alive: Array[Enemy] = []
var _debug_index: int = 0
var _far_check_timer: float = FAR_CHECK_INTERVAL


func start() -> void:
	elapsed = 0.0
	threat = profile.threat_at(0.0)
	_spawn_timer = profile.initial_delay
	running = true
	threat_changed.emit(threat)


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
	_spawn(entry, NavigationServer3D.map_get_closest_point(map, guess))
	print("Debug spawn: %s" % entry.enemy.display_name)


func alive_cost() -> float:
	var total: float = 0.0
	for enemy: Enemy in _alive:
		if is_instance_valid(enemy) and enemy.data != null:
			total += enemy.data.threat_cost
	return total


func _physics_process(delta: float) -> void:
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
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = profile.spawn_interval_for(threat)
		if not _try_spawn():
			_spawn_timer = minf(_spawn_timer, RETRY_DELAY)


func _try_spawn() -> bool:
	var budget_left: float = profile.budget_for(threat) - alive_cost()
	var entry: SpawnEntry = profile.pick_entry(threat, budget_left, randf())
	if entry == null:
		# Budget full: not a failure, just wait for the next interval.
		return true
	var point: Variant = _find_spawn_point()
	if point == null:
		return false
	_spawn(entry, point)
	return true


func _spawn(entry: SpawnEntry, point: Vector3) -> void:
	var enemy: Enemy = enemy_scene.instantiate() as Enemy
	enemy.data = entry.enemy
	enemy.damage_multiplier = profile.damage_multiplier_for(threat)
	enemy.speed_multiplier = profile.speed_multiplier_for(threat)
	enemy.position = point
	enemy.despawned.connect(_on_enemy_despawned)
	add_child(enemy)
	_alive.append(enemy)


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
		var point: Vector3 = NavigationServer3D.map_get_closest_point(map, guess)
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
		if enemy == null:
			continue
		var offset: Vector3 = enemy.global_position - origin
		if Vector2(offset.x, offset.z).length() > profile.despawn_distance:
			enemy.despawn()


func _on_enemy_despawned(enemy: Enemy) -> void:
	_alive.erase(enemy)
