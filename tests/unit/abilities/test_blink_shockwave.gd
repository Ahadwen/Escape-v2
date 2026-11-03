extends "res://tests/framework/test_case.gd"

const BlinkAbilityDataScript := preload("res://abilities/types/blink_ability_data.gd")


func test_no_shockwave_at_or_below_threshold() -> void:
	assert_almost_eq(BlinkAbilityDataScript.shockwave_strength(0.5, 0.5), -1.0)
	assert_almost_eq(BlinkAbilityDataScript.shockwave_strength(0.2, 0.5), -1.0)


func test_full_hp_is_full_strength() -> void:
	assert_almost_eq(BlinkAbilityDataScript.shockwave_strength(1.0, 0.5), 1.0)


func test_strength_scales_between_threshold_and_full() -> void:
	assert_almost_eq(BlinkAbilityDataScript.shockwave_strength(0.75, 0.5), 0.5)


func test_plough_pushes_to_the_side_enemy_is_on() -> void:
	var exec_script: GDScript = load("res://abilities/executions/charge_execution.gd")
	var left: Vector3 = exec_script.plough_direction(
		Vector3.FORWARD, Vector3.ZERO, Vector3(-1, 0, -1)
	)
	var right: Vector3 = exec_script.plough_direction(
		Vector3.FORWARD, Vector3.ZERO, Vector3(1, 0, -1)
	)
	assert_true(left.x < 0.0 and right.x > 0.0, "left %s right %s" % [left, right])
	# Both also carry a little forward (-Z).
	assert_true(left.z < 0.0 and right.z < 0.0)
	assert_almost_eq(left.length(), 1.0, 0.001)
