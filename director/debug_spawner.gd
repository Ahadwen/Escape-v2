class_name DebugSpawner
extends Node
## Temporary spawner for the greybox arena: keeps a fixed number of enemies
## alive around the player, replacing each one shortly after it despawns.
## The ThreatDirector replaces this in M4.

@export var enemy_scene: PackedScene
## Spawned in rotation.
@export var enemy_types: Array[EnemyData] = []
@export var count: int = 4
@export var player: Node3D
@export var min_distance: float = 10.0
@export var max_distance: float = 16.0
@export var respawn_delay: float = 2.0

var _next_type: int = 0
var _started: bool = false


## Call once the navmesh is baked.
func start() -> void:
	if _started:
		return
	_started = true
	# Let the navigation map sync before querying it.
	await get_tree().physics_frame
	await get_tree().physics_frame
	for i: int in count:
		_spawn_one()


func _spawn_one() -> void:
	if enemy_scene == null or enemy_types.is_empty() or player == null:
		return
	var map: RID = player.get_world_3d().navigation_map
	var angle: float = randf() * TAU
	var distance: float = randf_range(min_distance, max_distance)
	var guess: Vector3 = player.global_position + Vector3(cos(angle), 0.0, sin(angle)) * distance
	var point: Vector3 = NavigationServer3D.map_get_closest_point(map, guess)
	var enemy: Enemy = enemy_scene.instantiate() as Enemy
	enemy.data = enemy_types[_next_type % enemy_types.size()]
	_next_type += 1
	enemy.position = point
	enemy.despawned.connect(_on_enemy_despawned)
	add_child(enemy)


func _on_enemy_despawned(_enemy: Enemy) -> void:
	await get_tree().create_timer(respawn_delay).timeout
	if is_inside_tree():
		_spawn_one()
