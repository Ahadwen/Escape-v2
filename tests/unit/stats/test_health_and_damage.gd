extends "res://tests/framework/test_case.gd"

const ResourcePoolScript := preload("res://stats/resource_pool.gd")
const DamageResolverScript := preload("res://stats/damage_resolver.gd")
const DamageEventScript := preload("res://stats/damage_event.gd")
const StatBlockScript := preload("res://stats/stat_block.gd")


func test_pool_fill_and_fraction() -> void:
	var pool: ResourcePool = ResourcePoolScript.new()
	pool.set_maximum(400.0, true)
	assert_almost_eq(pool.current, 400.0)
	assert_almost_eq(pool.fraction(), 1.0)


func test_pool_drain_is_capped_and_reports_actual() -> void:
	var pool: ResourcePool = ResourcePoolScript.new()
	pool.set_maximum(100.0, true)
	assert_almost_eq(pool.drain(30.0), 30.0)
	assert_almost_eq(pool.drain(500.0), 70.0)
	assert_true(pool.is_empty())
	assert_almost_eq(pool.drain(10.0), 0.0)


func test_pool_depleted_signal_fires_once_on_empty() -> void:
	var pool: ResourcePool = ResourcePoolScript.new()
	pool.set_maximum(50.0, true)
	var count: Array[int] = [0]
	pool.depleted.connect(func() -> void: count[0] += 1)
	pool.drain(20.0)
	assert_eq(count[0], 0)
	pool.drain(40.0)
	assert_eq(count[0], 1)


func test_pool_restore_is_capped() -> void:
	var pool: ResourcePool = ResourcePoolScript.new()
	pool.set_maximum(100.0, true)
	pool.drain(30.0)
	assert_almost_eq(pool.restore(50.0), 30.0)
	assert_almost_eq(pool.current, 100.0)


func test_pool_lowering_max_clamps_current() -> void:
	var pool: ResourcePool = ResourcePoolScript.new()
	pool.set_maximum(100.0, true)
	pool.set_maximum(60.0)
	assert_almost_eq(pool.current, 60.0)


func test_pool_regen() -> void:
	var pool: ResourcePool = ResourcePoolScript.new()
	pool.set_maximum(100.0, true)
	pool.drain(50.0)
	pool.regen_per_second = 10.0
	pool.tick(2.0)
	assert_almost_eq(pool.current, 70.0)


func test_mitigation_zero_resistance_is_full_damage() -> void:
	assert_almost_eq(DamageResolverScript.mitigate(100.0, 0.0), 100.0)


func test_mitigation_100_resistance_halves() -> void:
	assert_almost_eq(DamageResolverScript.mitigate(100.0, 100.0), 50.0)


func test_mitigation_negative_resistance_amplifies() -> void:
	assert_almost_eq(DamageResolverScript.mitigate(100.0, -100.0), 150.0)


func test_physical_uses_armour_and_elemental_uses_resist() -> void:
	var stats: StatBlock = StatBlockScript.new()
	stats.set_base(StatIds.ARMOUR, 100.0)
	stats.set_base(StatIds.ELEMENTAL_RESIST, 0.0)
	var physical: DamageEvent = DamageEventScript.new(80.0, DamageEvent.DamageType.PHYSICAL)
	var elemental: DamageEvent = DamageEventScript.new(80.0, DamageEvent.DamageType.ELEMENTAL)
	assert_almost_eq(DamageResolverScript.resolve(physical, stats), 40.0)
	assert_almost_eq(DamageResolverScript.resolve(elemental, stats), 80.0)


func test_resolve_without_stats_is_unmitigated() -> void:
	var event: DamageEvent = DamageEventScript.new(25.0)
	assert_almost_eq(DamageResolverScript.resolve(event, null), 25.0)
