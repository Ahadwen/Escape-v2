extends "res://tests/framework/test_case.gd"

const StatBlockScript := preload("res://stats/stat_block.gd")
const StatModifierScript := preload("res://stats/stat_modifier.gd")
const StatScalingScript := preload("res://stats/stat_scaling.gd")

var block: StatBlock


func before_each() -> void:
	block = StatBlockScript.new()
	block.set_base(&"speed", 10.0)


func _mod(type: StatModifier.Type, value: float, source: StringName = &"") -> StatModifier:
	return StatModifierScript.new(&"speed", type, value, source)


func test_base_value_with_no_modifiers() -> void:
	assert_almost_eq(block.get_value(&"speed"), 10.0)


func test_unknown_stat_is_zero() -> void:
	assert_almost_eq(block.get_value(&"nope"), 0.0)
	assert_false(block.has_base(&"nope"))


func test_flat_modifier() -> void:
	block.add_modifier(_mod(StatModifier.Type.FLAT, 5.0))
	assert_almost_eq(block.get_value(&"speed"), 15.0)


func test_percent_add_modifiers_stack_additively() -> void:
	block.add_modifier(_mod(StatModifier.Type.PERCENT_ADD, 0.2))
	block.add_modifier(_mod(StatModifier.Type.PERCENT_ADD, 0.3))
	assert_almost_eq(block.get_value(&"speed"), 15.0)


func test_percent_mult_modifiers_stack_multiplicatively() -> void:
	block.add_modifier(_mod(StatModifier.Type.PERCENT_MULT, 0.5))
	block.add_modifier(_mod(StatModifier.Type.PERCENT_MULT, 1.0))
	assert_almost_eq(block.get_value(&"speed"), 30.0)


func test_order_flat_then_percent_add_then_mult() -> void:
	block.add_modifier(_mod(StatModifier.Type.PERCENT_MULT, 1.0))
	block.add_modifier(_mod(StatModifier.Type.PERCENT_ADD, 0.5))
	block.add_modifier(_mod(StatModifier.Type.FLAT, 10.0))
	# (10 + 10) * 1.5 * 2
	assert_almost_eq(block.get_value(&"speed"), 60.0)


func test_percent_add_cannot_go_negative() -> void:
	block.add_modifier(_mod(StatModifier.Type.PERCENT_ADD, -2.0))
	assert_almost_eq(block.get_value(&"speed"), 0.0)


func test_remove_modifier_restores_value() -> void:
	var modifier: StatModifier = _mod(StatModifier.Type.FLAT, 5.0)
	block.add_modifier(modifier)
	assert_almost_eq(block.get_value(&"speed"), 15.0)
	block.remove_modifier(modifier)
	assert_almost_eq(block.get_value(&"speed"), 10.0)


func test_remove_modifiers_from_source() -> void:
	block.add_modifier(_mod(StatModifier.Type.FLAT, 5.0, &"boots"))
	block.add_modifier(_mod(StatModifier.Type.FLAT, 5.0, &"boots"))
	block.add_modifier(_mod(StatModifier.Type.FLAT, 1.0, &"ring"))
	block.remove_modifiers_from(&"boots")
	assert_almost_eq(block.get_value(&"speed"), 11.0)


func test_modifiers_only_affect_their_stat() -> void:
	block.set_base(&"will", 3.0)
	block.add_modifier(_mod(StatModifier.Type.FLAT, 5.0))
	assert_almost_eq(block.get_value(&"will"), 3.0)


func test_changing_base_updates_cached_value() -> void:
	assert_almost_eq(block.get_value(&"speed"), 10.0)
	block.set_base(&"speed", 20.0)
	assert_almost_eq(block.get_value(&"speed"), 20.0)


func test_stat_changed_signal_fires() -> void:
	var changed: Array[StringName] = []
	block.stat_changed.connect(func(stat: StringName) -> void: changed.append(stat))
	block.add_modifier(_mod(StatModifier.Type.FLAT, 1.0))
	assert_eq(changed.size(), 1)
	assert_eq(changed[0], &"speed")


func test_scaling_evaluates_against_stat() -> void:
	block.set_base(&"will", 20.0)
	var scaling: StatScaling = StatScalingScript.new()
	scaling.stat = &"will"
	scaling.base_value = 5.0
	scaling.per_point = 0.05
	assert_almost_eq(scaling.evaluate(block), 6.0)


func test_scaling_without_stats_returns_base() -> void:
	var scaling: StatScaling = StatScalingScript.new()
	scaling.base_value = 4.0
	scaling.per_point = 1.0
	assert_almost_eq(scaling.evaluate(null), 4.0)
