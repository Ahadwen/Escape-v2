extends "res://tests/framework/test_case.gd"

const BulwarkEffectScript := preload("res://items/effects/bulwark_effect.gd")
const HealthComponentScript := preload("res://actors/components/health_component.gd")
const StatusEffectHostScript := preload("res://actors/components/status_effect_host.gd")
const StatsComponentScript := preload("res://actors/components/stats_component.gd")
const SpeedBoostScript := preload("res://status/speed_boost_effect.gd")
const DilationFieldScript := preload("res://enemies/dilation_field.gd")


func test_bulwark_arc() -> void:
	var facing: Vector3 = Vector3.FORWARD
	assert_true(BulwarkEffectScript.is_within_arc(facing, Vector3(0, 0, -5), 80.0))
	assert_true(BulwarkEffectScript.is_within_arc(facing, Vector3(1, 0, -3), 80.0))
	assert_false(BulwarkEffectScript.is_within_arc(facing, Vector3(1, 0, 0), 80.0))
	assert_false(BulwarkEffectScript.is_within_arc(facing, Vector3(0, 0, 5), 80.0))


func test_interceptors_can_block_and_reduce() -> void:
	var health: HealthComponent = HealthComponentScript.new()
	health.fallback_max = 100.0
	add_to_tree(health)
	var negated: Array[int] = [0]
	health.damage_negated.connect(func(_e: DamageEvent) -> void: negated[0] += 1)
	health.interceptors.append(func(_e: DamageEvent, amount: float) -> float: return amount * 0.5)
	health.take_damage(DamageEvent.new(40.0))
	assert_almost_eq(health.pool.current, 80.0)
	health.interceptors.append(func(_e: DamageEvent, _amount: float) -> float: return 0.0)
	health.take_damage(DamageEvent.new(40.0))
	assert_almost_eq(health.pool.current, 80.0)
	assert_eq(negated[0], 1)


func test_speed_boost_status_and_active_flag() -> void:
	var stats: StatsComponent = add_to_tree(StatsComponentScript.new()) as StatsComponent
	stats.block.set_base(StatIds.MOVE_SPEED, 8.0)
	var host: StatusEffectHost = add_to_tree(StatusEffectHostScript.new()) as StatusEffectHost
	host.stats = stats
	host.apply(SpeedBoostScript.new(2.0, 1.0, &"passive_boost", false, false))
	assert_almost_eq(stats.get_value(StatIds.MOVE_SPEED), 10.0)
	assert_false(host.has_active_speed_boost())
	host.apply(SpeedBoostScript.new(0.5, 1.0, &"active_boost", true, true))
	assert_almost_eq(stats.get_value(StatIds.MOVE_SPEED), 15.0)
	assert_true(host.has_active_speed_boost())
	host.tick(1.1)
	assert_almost_eq(stats.get_value(StatIds.MOVE_SPEED), 8.0)
	assert_false(host.has_active_speed_boost())


func test_dilation_field_scales_inside_only() -> void:
	DilationFieldScript.clear()
	var center: Node3D = add_to_tree(Node3D.new()) as Node3D
	var field: DilationField.Field = DilationFieldScript.add(center, 5.0, 0.6, 1.3)
	assert_almost_eq(DilationFieldScript.projectile_scale_at(Vector3(3, 0, 0)), 0.6)
	assert_almost_eq(DilationFieldScript.wind_up_scale_at(Vector3(3, 0, 0)), 1.3)
	assert_almost_eq(DilationFieldScript.projectile_scale_at(Vector3(9, 0, 0)), 1.0)
	DilationFieldScript.remove(field)
	assert_almost_eq(DilationFieldScript.projectile_scale_at(Vector3(3, 0, 0)), 1.0)


func test_ability_tags_and_duration_scale() -> void:
	var ability: AbilityData = AbilityData.new()
	ability.tags = PackedStringArray(["movement"])
	assert_true(ability.has_tag(AbilityData.TAG_MOVEMENT))
	assert_false(ability.has_tag(AbilityData.TAG_ULTIMATE))
	var stats: StatBlock = StatBlock.new()
	assert_almost_eq(AbilityData.duration_scale(stats), 1.0)
	stats.set_base(StatIds.ABILITY_DURATION, 0.3)
	assert_almost_eq(AbilityData.duration_scale(stats), 1.3)
	assert_almost_eq(AbilityData.duration_scale(null), 1.0)


func test_all_cards_in_library_load() -> void:
	var library: CardLibrary = load("res://items/data/card_library.tres") as CardLibrary
	assert_not_null(library)
	assert_eq(library.cards.size(), 53)
	for card: CardData in library.cards:
		assert_not_null(card, "a card failed to load")
	for tier: int in [1, 2, 3]:
		assert_eq(library.cards_of_tier(tier).size(), [0, 20, 16, 12][tier])
