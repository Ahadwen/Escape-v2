class_name SwarmAbility
extends HunterAbility
## The Broodmother's swarm: a telegraphed burst (a ring around her and a
## body flash), then a pack of short-lived mites rushes you.

const ENEMY_SCENE_PATH: String = "res://enemies/enemy.tscn"

@export var minion: EnemyData
@export var count: int = 8
@export var tell_time: float = 0.8
@export var spawn_radius: float = 1.8
@export var recovery: float = 0.5


func create_action(brain: HunterBrain) -> HunterAction:
	return Action.new(brain, self)


class Action:
	extends HunterAction

	var ability: SwarmAbility
	var _timer: float = 0.0
	var _spawned: bool = false

	func _init(p_brain: HunterBrain, p_ability: SwarmAbility) -> void:
		super(p_brain)
		ability = p_ability

	func start() -> void:
		enemy().movement.stop()
		enemy().set_tell(true)
		_timer = ability.tell_time
		brain.warning.show_circle(enemy().global_position, ability.spawn_radius + 1.0)

	func tick(delta: float) -> bool:
		_timer -= delta
		if _spawned:
			return _timer <= 0.0
		brain.warning.set_progress(1.0 - _timer / ability.tell_time)
		if _timer <= 0.0:
			_spawn()
		return false

	func cancel() -> void:
		brain.warning.clear()
		enemy().set_tell(false)

	func _spawn() -> void:
		cancel()
		_spawned = true
		_timer = ability.recovery
		if ability.minion == null:
			return
		# Loaded lazily: preloading the enemy scene here would be a cycle.
		var scene: PackedScene = load(ENEMY_SCENE_PATH) as PackedScene
		var map: RID = enemy().get_world_3d().navigation_map
		for i: int in ability.count:
			var angle: float = TAU * i / ability.count
			var offset: Vector3 = Vector3(cos(angle), 0.0, sin(angle)) * ability.spawn_radius
			var point: Vector3 = NavigationServer3D.map_get_closest_point(
				map, enemy().global_position + offset
			)
			enemy().spawn_minion(ability.minion, point, scene)
