extends "res://tests/framework/test_case.gd"

const AttackUtilsScript := preload("res://enemies/attacks/attack_utils.gd")


func test_point_on_segment_is_zero() -> void:
	var d: float = AttackUtilsScript.point_segment_distance_flat(
		Vector3(5, 0, 0), Vector3.ZERO, Vector3(10, 0, 0)
	)
	assert_almost_eq(d, 0.0)


func test_point_beside_segment() -> void:
	var d: float = AttackUtilsScript.point_segment_distance_flat(
		Vector3(5, 0, 3), Vector3.ZERO, Vector3(10, 0, 0)
	)
	assert_almost_eq(d, 3.0)


func test_point_past_end_measures_to_end() -> void:
	var d: float = AttackUtilsScript.point_segment_distance_flat(
		Vector3(13, 0, 4), Vector3.ZERO, Vector3(10, 0, 0)
	)
	assert_almost_eq(d, 5.0)


func test_height_is_ignored() -> void:
	var d: float = AttackUtilsScript.point_segment_distance_flat(
		Vector3(5, 40, 0), Vector3.ZERO, Vector3(10, 0, 0)
	)
	assert_almost_eq(d, 0.0)


func test_zero_length_segment() -> void:
	var d: float = AttackUtilsScript.point_segment_distance_flat(
		Vector3(3, 0, 4), Vector3.ZERO, Vector3.ZERO
	)
	assert_almost_eq(d, 5.0)
