extends "res://tests/framework/test_case.gd"

const ThreatProfileScript := preload("res://director/threat_profile.gd")
const SpawnEntryScript := preload("res://director/spawn_entry.gd")
const EnemyDataScript := preload("res://enemies/enemy_data.gd")

var profile: ThreatProfile
var cheap: SpawnEntry
var pricey: SpawnEntry


func _entry(cost: float, weight: float, min_threat: float) -> SpawnEntry:
	var enemy: EnemyData = EnemyDataScript.new()
	enemy.threat_cost = cost
	var entry: SpawnEntry = SpawnEntryScript.new()
	entry.enemy = enemy
	entry.weight = weight
	entry.min_threat = min_threat
	return entry


func before_each() -> void:
	profile = ThreatProfileScript.new()
	profile.start_threat = 1.0
	profile.threat_per_minute = 0.6
	profile.budget_per_threat = 2.0
	profile.base_spawn_interval = 6.0
	profile.min_spawn_interval = 1.5
	cheap = _entry(1.0, 3.0, 0.0)
	pricey = _entry(1.5, 1.0, 1.5)
	var entries: Array[SpawnEntry] = [cheap, pricey]
	profile.entries = entries


func test_threat_grows_linearly() -> void:
	assert_almost_eq(profile.threat_at(0.0), 1.0)
	assert_almost_eq(profile.threat_at(60.0), 1.6)
	assert_almost_eq(profile.threat_at(300.0), 4.0)


func test_budget_scales_with_threat() -> void:
	assert_almost_eq(profile.budget_for(2.0), 4.0)


func test_spawn_interval_shrinks_to_minimum() -> void:
	assert_almost_eq(profile.spawn_interval_for(1.0), 6.0)
	assert_almost_eq(profile.spawn_interval_for(2.0), 3.0)
	assert_almost_eq(profile.spawn_interval_for(10.0), 1.5)


func test_entry_locked_below_min_threat() -> void:
	for roll: float in [0.0, 0.5, 0.99]:
		assert_eq(profile.pick_entry(1.0, 10.0, roll), cheap)


func test_entries_unlock_with_threat_and_weights_apply() -> void:
	# Weights 3:1 -> rolls below 0.75 pick cheap, above pick pricey.
	assert_eq(profile.pick_entry(2.0, 10.0, 0.5), cheap)
	assert_eq(profile.pick_entry(2.0, 10.0, 0.9), pricey)


func test_budget_excludes_expensive_entries() -> void:
	assert_eq(profile.pick_entry(2.0, 1.2, 0.9), cheap)


func test_nothing_fits_returns_null() -> void:
	assert_null(profile.pick_entry(2.0, 0.5, 0.5))


func test_spawn_angle_ignores_heading_when_standing_still() -> void:
	profile.ahead_bias = 1.0
	assert_almost_eq(profile.spawn_angle(Vector3.ZERO, 0.0, 0.25), TAU * 0.25)


func test_spawn_angle_biased_ahead_when_moving() -> void:
	profile.ahead_bias = 1.0
	# Moving +Z: angle should be within 60 degrees of PI/2.
	for spread: float in [0.0, 0.5, 1.0]:
		var angle: float = profile.spawn_angle(Vector3(0, 0, 8), 0.0, spread)
		assert_true(absf(angle_difference(angle, PI / 2.0)) <= PI / 3.0 + 0.001, "angle %f" % angle)


func test_spawn_angle_bias_roll_above_bias_is_random() -> void:
	profile.ahead_bias = 0.5
	assert_almost_eq(profile.spawn_angle(Vector3(0, 0, 8), 0.9, 0.5), PI)
