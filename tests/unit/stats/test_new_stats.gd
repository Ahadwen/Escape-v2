extends "res://tests/framework/test_case.gd"

const AbilitySlotScript := preload("res://abilities/ability_slot.gd")
const AbilityDataScript := preload("res://abilities/ability_data.gd")
const CastContextScript := preload("res://abilities/cast_context.gd")
const HealthComponentScript := preload("res://actors/components/health_component.gd")
const PauseControllerScript := preload("res://core/pause_controller.gd")


func test_haste_has_diminishing_returns() -> void:
	assert_almost_eq(StatIds.haste_multiplier(0.0), 1.0)
	assert_almost_eq(StatIds.haste_multiplier(100.0), 0.5)
	assert_almost_eq(StatIds.haste_multiplier(25.0), 0.8)
	assert_true(StatIds.haste_multiplier(1000.0) > 0.0)


func test_cooldown_uses_multiplier_and_override() -> void:
	var slot: AbilitySlot = AbilitySlotScript.new(0)
	var ability: AbilityData = AbilityDataScript.new()
	ability.cooldown = 10.0
	slot.set_ability(ability)
	slot.cooldown_multiplier = 0.5
	slot.try_cast(CastContextScript.new(null, null, null, null))
	assert_almost_eq(slot.cooldown_remaining, 5.0)
	slot.cooldown_remaining = 0.0
	slot.next_cooldown_override = 0.2
	slot.try_cast(CastContextScript.new(null, null, null, null))
	assert_almost_eq(slot.cooldown_remaining, 0.2)
	# The override is used once.
	slot.cooldown_remaining = 0.0
	slot.try_cast(CastContextScript.new(null, null, null, null))
	assert_almost_eq(slot.cooldown_remaining, 5.0)


func test_damage_log_and_pay_hp() -> void:
	var health: HealthComponent = HealthComponentScript.new()
	health.fallback_max = 100.0
	add_to_tree(health)
	health.take_damage(DamageEvent.new(30.0))
	health.take_damage(DamageEvent.new(20.0))
	assert_almost_eq(health.damage_in_last(1.5), 50.0)
	# Paying HP isn't damage and can't kill.
	health.time_since_damage = 10.0
	assert_almost_eq(health.pay_hp(500.0), 49.0)
	assert_almost_eq(health.pool.current, 1.0)
	assert_almost_eq(health.time_since_damage, 10.0)
	assert_false(health.is_dead)


func test_gameplay_press_detection() -> void:
	var q: InputEventKey = InputEventKey.new()
	q.physical_keycode = KEY_Q
	q.pressed = true
	assert_true(PauseControllerScript.is_gameplay_press(q), "Q (an ability) unpauses")
	var alt: InputEventKey = InputEventKey.new()
	alt.physical_keycode = KEY_ALT
	alt.pressed = true
	assert_false(PauseControllerScript.is_gameplay_press(alt), "Alt doesn't unpause")
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	assert_false(PauseControllerScript.is_gameplay_press(motion))
	var stick: InputEventJoypadMotion = InputEventJoypadMotion.new()
	stick.axis_value = 0.2
	assert_false(PauseControllerScript.is_gameplay_press(stick))
	stick.axis_value = 0.9
	assert_true(PauseControllerScript.is_gameplay_press(stick))


func test_enemy_time_slow_and_expiry() -> void:
	EnemyTime.reset()
	assert_almost_eq(EnemyTime.scale(), 1.0)
	EnemyTime.slow(0.7, 3.0)
	assert_almost_eq(EnemyTime.scale(), 0.7)
	EnemyTime.tick(3.1)
	assert_almost_eq(EnemyTime.scale(), 1.0)
	EnemyTime.reset()
