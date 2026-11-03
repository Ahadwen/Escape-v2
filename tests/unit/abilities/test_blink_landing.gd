extends "res://tests/framework/test_case.gd"

const BlinkLandingScript := preload("res://abilities/blink_landing.gd")


## Floor everywhere in x < 20, except a wall occupying wall_min..wall_max on X.
func _walkable_with_wall(wall_min: float, wall_max: float) -> Callable:
	return func(p: Vector3) -> bool: return p.x < 20.0 and not (p.x > wall_min and p.x < wall_max)


func test_open_ground_lands_at_full_range() -> void:
	var landing: Variant = BlinkLandingScript.find(
		Vector3.ZERO, Vector3.RIGHT, 5.0, _walkable_with_wall(100.0, 101.0)
	)
	assert_eq(landing, Vector3(5, 0, 0))


func test_passes_over_wall_to_open_ground() -> void:
	var landing: Variant = BlinkLandingScript.find(
		Vector3.ZERO, Vector3.RIGHT, 5.0, _walkable_with_wall(2.0, 3.0)
	)
	assert_eq(landing, Vector3(5, 0, 0))


func test_mid_wall_lands_on_near_side_when_closer() -> void:
	# Aim at 5, wall 4.5..7: near side (4.5) is 0.5 back, far side (7) is 2 on.
	var landing: Variant = BlinkLandingScript.find(
		Vector3.ZERO, Vector3.RIGHT, 5.0, _walkable_with_wall(4.5, 7.0)
	)
	assert_not_null(landing)
	var point: Vector3 = landing
	assert_true(point.x <= 4.5 and point.x > 4.3, "landed at %s" % point)


func test_mid_wall_lands_on_far_side_when_closer() -> void:
	# Aim at 5, wall 3..5.5: far side (5.5) is 0.5 on, near side (3) is 2 back.
	var landing: Variant = BlinkLandingScript.find(
		Vector3.ZERO, Vector3.RIGHT, 5.0, _walkable_with_wall(3.0, 5.5)
	)
	assert_not_null(landing)
	var point: Vector3 = landing
	assert_true(point.x >= 5.5 and point.x < 5.7, "landed at %s" % point)


func test_boundary_lands_on_near_side() -> void:
	# Nothing walkable beyond x = 20 (outside the level).
	var landing: Variant = BlinkLandingScript.find(
		Vector3(18, 0, 0), Vector3.RIGHT, 5.0, _walkable_with_wall(100.0, 101.0)
	)
	assert_not_null(landing)
	var point: Vector3 = landing
	assert_true(point.x < 20.0 and point.x > 19.8, "landed at %s" % point)


func test_nowhere_walkable_returns_null() -> void:
	var nowhere: Callable = func(_p: Vector3) -> bool: return false
	assert_null(BlinkLandingScript.find(Vector3.ZERO, Vector3.RIGHT, 5.0, nowhere))


func test_direction_is_flattened() -> void:
	var landing: Variant = BlinkLandingScript.find(
		Vector3.ZERO, Vector3(1, 1, 0), 5.0, _walkable_with_wall(100.0, 101.0)
	)
	assert_eq(landing, Vector3(5, 0, 0))
