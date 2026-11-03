class_name ThreatProfile
extends Resource
## How threat grows over a level and how it turns into spawns. Pure data and
## pure functions, so the whole curve is unit-testable and tunable as data.
##
## threat(t)        = start_threat + threat_per_minute * minutes
## alive budget     = threat * budget_per_threat   (sum of alive enemies' threat_cost)
## spawn interval   = max(min_spawn_interval, base_spawn_interval / threat)

@export var start_threat: float = 1.0
@export var threat_per_minute: float = 0.6
## Threat cost of enemies allowed alive at once, per point of threat.
@export var budget_per_threat: float = 2.0
@export var base_spawn_interval: float = 6.0
@export var min_spawn_interval: float = 1.5
## Seconds of calm at the start of the level.
@export var initial_delay: float = 3.0

@export_group("Placement")
@export var spawn_distance_min: float = 18.0
@export var spawn_distance_max: float = 26.0

@export_group("Enemies")
@export var entries: Array[SpawnEntry] = []


func threat_at(seconds: float) -> float:
	return start_threat + threat_per_minute * seconds / 60.0


func budget_for(threat: float) -> float:
	return maxf(threat, 0.0) * budget_per_threat


func spawn_interval_for(threat: float) -> float:
	if threat <= 0.0:
		return base_spawn_interval
	return maxf(min_spawn_interval, base_spawn_interval / threat)


## Picks an entry allowed at this threat that fits in budget_left, weighted.
## roll is in [0, 1). Returns null if nothing fits.
func pick_entry(threat: float, budget_left: float, roll: float) -> SpawnEntry:
	var allowed: Array[SpawnEntry] = []
	var total: float = 0.0
	for entry: SpawnEntry in entries:
		if entry.enemy == null or entry.weight <= 0.0:
			continue
		if entry.min_threat <= threat and entry.cost() <= budget_left:
			allowed.append(entry)
			total += entry.weight
	if allowed.is_empty():
		return null
	var target: float = clampf(roll, 0.0, 0.999999) * total
	for entry: SpawnEntry in allowed:
		target -= entry.weight
		if target < 0.0:
			return entry
	return allowed[-1]
