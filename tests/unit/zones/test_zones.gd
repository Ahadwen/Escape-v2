extends "res://tests/framework/test_case.gd"

const ZoneDataScript := preload("res://zones/zone_data.gd")
const ObstacleKindScript := preload("res://zones/obstacle_kind.gd")
const LevelThemeScript := preload("res://zones/level_theme.gd")
const EnemyVariantScript := preload("res://zones/enemy_variant.gd")
const EnemyDataScript := preload("res://enemies/enemy_data.gd")
const FlameConeScript := preload("res://enemies/attacks/flame_cone.gd")
const StatusEffectHostScript := preload("res://actors/components/status_effect_host.gd")
const HealthComponentScript := preload("res://actors/components/health_component.gd")
const BurnEffectScript := preload("res://status/burn_effect.gd")


func _zone(kind: StringName, ground: Color) -> ZoneData:
	var zone: ZoneData = ZoneDataScript.new()
	zone.ground_color_a = ground
	zone.ground_color_b = ground
	var k: ObstacleKind = ObstacleKindScript.new()
	k.kind = kind
	var kit: Array[ObstacleKind] = [k]
	zone.obstacle_kit = kit
	return zone


func test_intensity_zero_is_all_neutral_one_is_all_zone() -> void:
	var neutral: ZoneData = _zone(&"pillar", Color.GREEN)
	var inferno: ZoneData = _zone(&"spire", Color.RED)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var none: LevelTheme = LevelThemeScript.new(neutral, inferno, 0.0)
	var full: LevelTheme = LevelThemeScript.new(neutral, inferno, 1.0)
	for i: int in 20:
		assert_eq(none.pick_obstacle(rng).kind, &"pillar")
		assert_eq(full.pick_obstacle(rng).kind, &"spire")
	assert_eq(none.ground_color(0.5), Color.GREEN)
	assert_eq(full.ground_color(0.5), Color.RED)


func test_half_intensity_blends_colour_and_mixes_obstacles() -> void:
	var neutral: ZoneData = _zone(&"pillar", Color(0, 0, 0))
	var inferno: ZoneData = _zone(&"spire", Color(1, 1, 1))
	var theme: LevelTheme = LevelThemeScript.new(neutral, inferno, 0.5)
	assert_almost_eq(theme.ground_color(0.0).r, 0.5, 0.001)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 3
	var spires: int = 0
	for i: int in 400:
		if theme.pick_obstacle(rng).kind == &"spire":
			spires += 1
	assert_true(spires > 150 and spires < 250, "spires %d" % spires)


func test_variants_replace_by_chance_of_intensity() -> void:
	var base: EnemyData = EnemyDataScript.new()
	base.id = &"gunner"
	var fiery: EnemyData = EnemyDataScript.new()
	fiery.id = &"gunner"
	var inferno: ZoneData = _zone(&"spire", Color.RED)
	var entry: EnemyVariant = EnemyVariantScript.new()
	entry.base_id = &"gunner"
	entry.variant = fiery
	var variants: Array[EnemyVariant] = [entry]
	inferno.enemy_variants = variants
	var theme: LevelTheme = LevelThemeScript.new(_zone(&"pillar", Color.GREEN), inferno, 0.25)
	assert_eq(theme.enemy_for(base, 0.1), fiery)
	assert_eq(theme.enemy_for(base, 0.5), base)
	var other: EnemyData = EnemyDataScript.new()
	other.id = &"chaser"
	assert_eq(theme.enemy_for(other, 0.0), other)


func test_hits_ignite_only_when_zone_present() -> void:
	var inferno: ZoneData = _zone(&"spire", Color.RED)
	inferno.hits_ignite = true
	var neutral: ZoneData = _zone(&"pillar", Color.GREEN)
	assert_false(LevelThemeScript.new(neutral, inferno, 0.0).hits_ignite())
	assert_true(LevelThemeScript.new(neutral, inferno, 0.25).hits_ignite())


func test_registry_files_load() -> void:
	var registry: ZoneRegistry = load("res://zones/data/zone_registry.tres") as ZoneRegistry
	assert_not_null(registry)
	assert_not_null(registry.neutral)
	assert_eq(registry.destinations.size(), 1)
	assert_almost_eq(registry.intensity_for(0), 0.0)
	assert_almost_eq(registry.intensity_for(4), 1.0)
	assert_almost_eq(registry.intensity_for(99), 1.0)
	var inferno: ZoneData = registry.destination_for_seed(12345)
	assert_eq(inferno.id, &"inferno")
	assert_not_null(inferno.variant_for(&"artillery"))
	assert_eq(inferno.obstacle_kit.size(), 4)


func test_flame_cone_band() -> void:
	var at: Vector3 = Vector3.ZERO
	var dir: Vector3 = Vector3.FORWARD
	var angle: float = deg_to_rad(7.5)
	assert_true(FlameConeScript.in_band(at, dir, angle, 5.0, 1.2, Vector3(0, 0, -5)))
	assert_false(FlameConeScript.in_band(at, dir, angle, 5.0, 1.2, Vector3(0, 0, -8)))
	assert_false(FlameConeScript.in_band(at, dir, angle, 5.0, 1.2, Vector3(4, 0, -3)))


func test_burn_ticks_damage_and_is_flagged() -> void:
	var health: HealthComponent = HealthComponentScript.new()
	health.fallback_max = 100.0
	add_to_tree(health)
	var host: StatusEffectHost = add_to_tree(StatusEffectHostScript.new()) as StatusEffectHost
	host.health = health
	var burn_hits: Array[int] = [0]
	health.damaged.connect(
		func(_a: float, event: DamageEvent) -> void: burn_hits[0] += 1 if event.is_burn else 0
	)
	host.apply(BurnEffectScript.new(2.0, 1.0, 6.0))
	host.tick(0.5)
	host.tick(0.6)
	assert_almost_eq(health.pool.current, 94.0)
	host.tick(1.0)
	assert_almost_eq(health.pool.current, 88.0)
	assert_eq(burn_hits[0], 2)
	assert_false(host.has_effect(BurnEffect.ID))
