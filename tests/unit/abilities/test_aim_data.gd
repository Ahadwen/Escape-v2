extends "res://tests/framework/test_case.gd"

const AimDataScript := preload("res://abilities/aim_data.gd")
const CastContextScript := preload("res://abilities/cast_context.gd")


func test_none_is_none() -> void:
	assert_true(AimDataScript.none().is_none())


func test_from_point_gives_flat_direction() -> void:
	var aim: AimData = AimDataScript.from_point(Vector3(0, 1, 0), Vector3(3, 0, 4))
	assert_true(aim.has_point)
	assert_almost_eq(aim.direction.x, 0.6)
	assert_almost_eq(aim.direction.y, 0.0)
	assert_almost_eq(aim.direction.z, 0.8)


func test_from_point_on_origin_has_no_direction() -> void:
	var aim: AimData = AimDataScript.from_point(Vector3.ZERO, Vector3.ZERO)
	assert_eq(aim.direction, Vector3.ZERO)
	assert_false(aim.is_none())


func test_from_direction_normalises_and_clamps_strength() -> void:
	var aim: AimData = AimDataScript.from_direction(Vector3(2, 5, 0), 3.0)
	assert_eq(aim.direction, Vector3.RIGHT)
	assert_almost_eq(aim.strength, 1.0)


func test_from_zero_direction_is_none() -> void:
	assert_true(AimDataScript.from_direction(Vector3.ZERO).is_none())


func test_aim_point_is_clamped_to_range() -> void:
	var caster: Node3D = add_to_tree(Node3D.new()) as Node3D
	var aim: AimData = AimDataScript.from_point(Vector3.ZERO, Vector3(10, 0, 0))
	var context: CastContext = CastContextScript.new(caster, null, null, aim)
	assert_eq(context.aim_point(4.0), Vector3(4, 0, 0))


func test_aim_point_from_stick_uses_strength() -> void:
	var caster: Node3D = add_to_tree(Node3D.new()) as Node3D
	var aim: AimData = AimDataScript.from_direction(Vector3.BACK, 0.5)
	var context: CastContext = CastContextScript.new(caster, null, null, aim)
	assert_eq(context.aim_point(4.0), Vector3(0, 0, 2))


func test_no_aim_falls_back_to_caster_forward() -> void:
	var caster: Node3D = add_to_tree(Node3D.new()) as Node3D
	var context: CastContext = CastContextScript.new(caster, null, null, AimDataScript.none())
	assert_eq(context.aim_direction(), Vector3.FORWARD)
