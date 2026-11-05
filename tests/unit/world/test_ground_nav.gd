extends "res://tests/framework/test_case.gd"


func test_ground_is_near_the_asked_height() -> void:
	assert_true(GroundNav.is_ground(Vector3(0, 0.2, 0), 0.0))
	assert_false(GroundNav.is_ground(Vector3(0, 1.2, 0), 0.0), "a low slab's top isn't ground")
	assert_false(GroundNav.is_ground(Vector3(0, 2.0, 0), 0.0))
