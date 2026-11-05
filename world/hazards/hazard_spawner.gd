class_name HazardSpawner
extends Node
## Spawns a zone's ground hazards around the player during a level, at a
## rate that scales with zone intensity and threat. Never on top of them.

@export var player: Node3D
@export var director: ThreatDirector

var _rules: Array[HazardRule] = []
var _intensity: float = 0.0
var _alive: Array[Node3D] = []
var _running: bool = false


func start(theme: LevelTheme) -> void:
	_rules = theme.zone.hazards
	_intensity = theme.intensity
	_running = _intensity > 0.0 and not _rules.is_empty()


func stop() -> void:
	_running = false


func _physics_process(delta: float) -> void:
	if not _running or player == null:
		return
	for i: int in range(_alive.size() - 1, -1, -1):
		if not is_instance_valid(_alive[i]):
			_alive.remove_at(i)
	var threat: float = director.threat if director != null else 1.0
	for rule: HazardRule in _rules:
		var cap: int = maxi(roundi(rule.max_alive * _intensity), 1)
		if _alive.size() >= cap or rule.hazard_scene == null:
			continue
		var rate: float = (rule.base_rate + rule.rate_per_threat * threat) * _intensity
		if randf() < rate * delta:
			_spawn(rule)


func _spawn(rule: HazardRule) -> void:
	var map: RID = player.get_world_3d().navigation_map
	var angle: float = randf() * TAU
	var distance: float = randf_range(rule.min_distance, rule.max_distance)
	var guess: Vector3 = player.global_position + Vector3(cos(angle), 0.0, sin(angle)) * distance
	var point: Vector3 = GroundNav.closest_point(map, guess)
	var offset: Vector3 = point - player.global_position
	if Vector2(offset.x, offset.z).length() < rule.min_distance * 0.8:
		return
	var hazard: Node3D = rule.hazard_scene.instantiate() as Node3D
	hazard.position = point
	add_child(hazard)
	_alive.append(hazard)
