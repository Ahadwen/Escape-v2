extends "res://tests/framework/test_case.gd"

const ThreatProfileScript := preload("res://director/threat_profile.gd")
const SpawnEntryScript := preload("res://director/spawn_entry.gd")
const EnemyDataScript := preload("res://enemies/enemy_data.gd")
const MomentumScript := preload("res://actors/movement/momentum_movement.gd")
const AttackUtilsScript := preload("res://enemies/attacks/attack_utils.gd")
const StatBlockScript := preload("res://stats/stat_block.gd")
const BarrageScript := preload("res://enemies/hunters/abilities/barrage_ability.gd")
const HeadOffScript := preload("res://enemies/hunters/abilities/head_off_ability.gd")

const DT: float = 1.0 / 60.0


func _entry(id: StringName, min_threat: float, max_threat: float) -> SpawnEntry:
	var enemy: EnemyData = EnemyDataScript.new()
	enemy.id = id
	enemy.threat_cost = 1.0
	var entry: SpawnEntry = SpawnEntryScript.new()
	entry.enemy = enemy
	entry.min_threat = min_threat
	entry.max_threat = max_threat
	return entry


func test_field_size_grows_with_threat_to_cap() -> void:
	var profile: ThreatProfile = ThreatProfileScript.new()
	profile.start_threat = 2.0
	profile.max_alive_start = 2
	profile.max_alive_per_threat = 0.5
	profile.max_alive_cap = 5
	assert_eq(profile.max_alive_for(2.0), 2)
	assert_eq(profile.max_alive_for(4.0), 3)
	assert_eq(profile.max_alive_for(50.0), 5)


func test_threat_window_and_exclusions() -> void:
	var profile: ThreatProfile = ThreatProfileScript.new()
	var shambler: SpawnEntry = _entry(&"shambler", 0.0, 3.5)
	var brute: SpawnEntry = _entry(&"brute", 2.0, 0.0)
	var entries: Array[SpawnEntry] = [shambler, brute]
	profile.entries = entries
	assert_eq(profile.pick_entry(1.0, 100.0, 0.99), shambler)
	assert_eq(profile.pick_entry(5.0, 100.0, 0.01), brute)
	var exclude: Array[StringName] = [&"brute"]
	assert_eq(profile.pick_entry(3.0, 100.0, 0.99, exclude), shambler)
	assert_null(profile.pick_entry(5.0, 100.0, 0.5, exclude))


func test_momentum_accelerates_then_coasts_to_stop() -> void:
	var move: MomentumMovement = MomentumScript.new(
		Vector3.FORWARD, 6.0, 24.0, 30.0, 14.0, 1.0, 1.0
	)
	var peak: float = 0.0
	var frames: int = 0
	while not move.finished and frames < 1000:
		peak = maxf(peak, move.compute_velocity(DT).length())
		frames += 1
	assert_almost_eq(peak, 24.0, 0.01)
	assert_true(move.finished)
	# 1 s driving, then ~1.7 s slowing from 24 m/s at 14 m/s².
	assert_true(frames > 140 and frames < 190, "frames %d" % frames)


func test_momentum_turns_with_limited_rate() -> void:
	var move: MomentumMovement = MomentumScript.new(
		Vector3.FORWARD, 10.0, 10.0, 0.0, 10.0, deg_to_rad(45.0), 5.0
	)
	move.steer_direction = Vector3.BACK
	move.compute_velocity(1.0)
	assert_almost_eq(rad_to_deg(Vector3.FORWARD.angle_to(move.direction)), 45.0, 0.5)


func test_cone_hit_test() -> void:
	var at: Vector3 = Vector3.ZERO
	assert_true(AttackUtilsScript.in_cone(at, Vector3.FORWARD, 3.0, 90.0, Vector3(0, 0, -2)))
	assert_true(AttackUtilsScript.in_cone(at, Vector3.FORWARD, 3.0, 90.0, Vector3(1, 0, -2)))
	assert_false(AttackUtilsScript.in_cone(at, Vector3.FORWARD, 3.0, 90.0, Vector3(2, 0, 0)))
	assert_false(AttackUtilsScript.in_cone(at, Vector3.FORWARD, 3.0, 90.0, Vector3(0, 0, -4)))


func test_sustained_speed_ignores_status_boosts() -> void:
	var block: StatBlock = StatBlockScript.new()
	block.set_base(StatIds.MOVE_SPEED, 8.0)
	block.add_modifier(StatModifier.new(StatIds.MOVE_SPEED, StatModifier.Type.FLAT, 0.6, &"cards"))
	block.add_modifier(
		StatModifier.new(StatIds.MOVE_SPEED, StatModifier.Type.PERCENT_ADD, 0.8, &"status:parry")
	)
	assert_almost_eq(block.get_value_excluding(StatIds.MOVE_SPEED, "status:"), 8.6)
	assert_almost_eq(block.get_value(StatIds.MOVE_SPEED), 8.6 * 1.8)


func test_hunter_data_files_load() -> void:
	for id: String in [
		"shambler",
		"brute",
		"spinner",
		"harpooner",
		"gunslinger",
		"trapper",
		"assassin",
		"artillerist",
		"broodmother",
	]:
		var hunter: HunterData = load("res://enemies/data/hunters/%s.tres" % id) as HunterData
		assert_not_null(hunter, id)
		assert_false(hunter.abilities.is_empty(), "%s has abilities" % id)


func test_barrage_scatter_centres_on_you_without_overlaps() -> void:
	var barrage: BarrageAbility = BarrageScript.new()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var circles: Array[Vector3] = barrage.scatter(Vector3(10, 0, 5), rng)
	assert_true(circles.size() >= barrage.count - 2, "most circles placed: %d" % circles.size())
	assert_almost_eq(circles[0].x, 10.0)
	assert_almost_eq(circles[0].z, 5.0)
	for a: int in circles.size():
		var from_you: float = Vector2(circles[a].x - 10.0, circles[a].z - 5.0).length()
		assert_true(from_you <= barrage.spread + 0.01, "within spread")
		for b: int in range(a + 1, circles.size()):
			var apart: Vector2 = Vector2(circles[a].x - circles[b].x, circles[a].z - circles[b].z)
			assert_true(apart.length() >= circles[a].y + circles[b].y, "no overlap")


func test_hunt_roster_has_every_hunter() -> void:
	var hunt: ThreatProfile = load("res://director/data/hunt.tres") as ThreatProfile
	var ids: Array[StringName] = []
	for entry: SpawnEntry in hunt.entries:
		ids.append(entry.enemy.id)
	for id: StringName in [&"gunslinger", &"trapper", &"assassin", &"artillerist", &"broodmother"]:
		assert_true(id in ids, "%s in the hunt" % id)


func test_head_off_destination_is_ahead_of_heading() -> void:
	var ability: HeadOffAbility = HeadOffScript.new()
	ability.ahead_distance = 15.0
	ability.min_distance = 9.0
	var point: Vector3 = ability.destination(Vector3.ZERO, Vector3(8, 0, 0), 0.0)
	assert_almost_eq(point.x, 15.0, 0.01)
	assert_almost_eq(point.z, 0.0, 0.01)
	var side: Vector3 = ability.destination(Vector3.ZERO, Vector3(8, 0, 0), 5.0)
	assert_almost_eq(side.x, 15.0, 0.01)
	assert_almost_eq(absf(side.z), 5.0, 0.01)
