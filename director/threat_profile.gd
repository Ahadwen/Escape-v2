class_name ThreatProfile
extends Resource
## How threat grows over a level and how it turns into spawns. Pure data and
## pure functions, so the whole curve is unit-testable and tunable as data.
##
## threat(t)        = level start + level rate * minutes, where each level
##                    starts and ramps a bit higher than the last
##                    (but well below where the previous level would be)
## alive budget     = threat * budget_per_threat   (sum of alive enemies' threat_cost)
## spawn interval   = max(min_spawn_interval, base_spawn_interval / threat)

@export var start_threat: float = 1.0
@export var threat_per_minute: float = 0.6
## Added to start_threat for each level after the first.
@export var level_start_step: float = 1.0
## threat_per_minute grows by this fraction for each level after the first.
@export var level_rate_step: float = 0.2

## Threat cost of enemies allowed alive at once, per point of threat.
@export var budget_per_threat: float = 2.0
@export var base_spawn_interval: float = 6.0
@export var min_spawn_interval: float = 1.5
## Seconds of calm at the start of the level.
@export var initial_delay: float = 3.0

@export_group("Placement")
@export var spawn_distance_min: float = 18.0
@export var spawn_distance_max: float = 26.0
## Chance a spawn is placed ahead of the player's direction of travel
## (within ±60°) rather than anywhere around them. Stops "just walk away".
@export_range(0.0, 1.0) var ahead_bias: float = 0.65
## Below this speed the player counts as standing still (no ahead bias).
@export var ahead_min_speed: float = 2.0
## Enemies further than this from the player despawn (they'd be in
## unloaded terrain), freeing their budget.
@export var despawn_distance: float = 60.0

@export_group("Danger scaling")
## Enemies spawned at higher threat hit harder and move faster. Both scale
## with threat above start_threat, up to a cap.
@export var damage_per_threat: float = 0.08
@export var max_damage_multiplier: float = 2.0
@export var speed_per_threat: float = 0.03
@export var max_speed_multiplier: float = 1.3

@export_group("Enemies")
@export var entries: Array[SpawnEntry] = []

## Which level (0-based) the curve is for. Set by the director.
var level: int = 0


func level_start_threat() -> float:
	return start_threat + level_start_step * level


func level_threat_per_minute() -> float:
	return threat_per_minute * (1.0 + level_rate_step * level)


func threat_at(seconds: float) -> float:
	return level_start_threat() + level_threat_per_minute() * seconds / 60.0


func budget_for(threat: float) -> float:
	return maxf(threat, 0.0) * budget_per_threat


func damage_multiplier_for(threat: float) -> float:
	var extra: float = maxf(threat - start_threat, 0.0) * damage_per_threat
	return minf(1.0 + extra, max_damage_multiplier)


func speed_multiplier_for(threat: float) -> float:
	var extra: float = maxf(threat - start_threat, 0.0) * speed_per_threat
	return minf(1.0 + extra, max_speed_multiplier)


func spawn_interval_for(threat: float) -> float:
	if threat <= 0.0:
		return base_spawn_interval
	return maxf(min_spawn_interval, base_spawn_interval / threat)


## Angle (radians, around Y from +X) for a spawn. heading is the player's flat
## velocity; rolls are in [0, 1).
func spawn_angle(heading: Vector3, bias_roll: float, spread_roll: float) -> float:
	var flat: Vector2 = Vector2(heading.x, heading.z)
	if flat.length() >= ahead_min_speed and bias_roll < ahead_bias:
		return flat.angle() + lerpf(-PI / 3.0, PI / 3.0, spread_roll)
	return spread_roll * TAU


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
