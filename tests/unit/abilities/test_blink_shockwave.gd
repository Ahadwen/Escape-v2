extends "res://tests/framework/test_case.gd"

const BlinkAbilityDataScript := preload("res://abilities/types/blink_ability_data.gd")


func test_no_shockwave_at_or_below_threshold() -> void:
	assert_almost_eq(BlinkAbilityDataScript.shockwave_strength(0.5, 0.5), -1.0)
	assert_almost_eq(BlinkAbilityDataScript.shockwave_strength(0.2, 0.5), -1.0)


func test_full_hp_is_full_strength() -> void:
	assert_almost_eq(BlinkAbilityDataScript.shockwave_strength(1.0, 0.5), 1.0)


func test_strength_scales_between_threshold_and_full() -> void:
	assert_almost_eq(BlinkAbilityDataScript.shockwave_strength(0.75, 0.5), 0.5)
