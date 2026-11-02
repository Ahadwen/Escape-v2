extends "res://tests/framework/test_case.gd"

const InputMathScript := preload("res://input/input_math.gd")


func _iso_basis() -> Basis:
	# Same orientation as IsometricCamera defaults: yaw 45, pitch -50.
	return Basis.from_euler(Vector3(deg_to_rad(-50.0), deg_to_rad(45.0), 0.0))


func test_stick_zero_gives_zero() -> void:
	assert_eq(InputMathScript.stick_to_world(Vector2.ZERO, _iso_basis()), Vector3.ZERO)


func test_stick_up_moves_away_from_camera() -> void:
	var basis: Basis = _iso_basis()
	var world: Vector3 = InputMathScript.stick_to_world(Vector2(0.0, -1.0), basis)
	var view_forward: Vector3 = Vector3(-basis.z.x, 0.0, -basis.z.z).normalized()
	assert_almost_eq(world.y, 0.0)
	assert_almost_eq(world.dot(view_forward), 1.0, 0.001)


func test_stick_right_moves_screen_right() -> void:
	var basis: Basis = _iso_basis()
	var world: Vector3 = InputMathScript.stick_to_world(Vector2(1.0, 0.0), basis)
	var screen_right: Vector3 = Vector3(basis.x.x, 0.0, basis.x.z).normalized()
	assert_almost_eq(world.dot(screen_right), 1.0, 0.001)


func test_stick_output_is_flat_and_clamped() -> void:
	var world: Vector3 = InputMathScript.stick_to_world(Vector2(1.0, -1.0), _iso_basis())
	assert_almost_eq(world.y, 0.0)
	assert_almost_eq(world.length(), 1.0, 0.001)


func test_stick_works_when_camera_looks_straight_down() -> void:
	var down: Basis = Basis.from_euler(Vector3(deg_to_rad(-90.0), 0.0, 0.0))
	var world: Vector3 = InputMathScript.stick_to_world(Vector2(0.0, -1.0), down)
	assert_almost_eq(world.length(), 1.0, 0.001)
	assert_almost_eq(world.z, -1.0, 0.001)


func test_ray_hits_ground() -> void:
	var hit: Variant = InputMathScript.ray_to_ground(Vector3(2.0, 10.0, 3.0), Vector3.DOWN)
	assert_eq(hit, Vector3(2.0, 0.0, 3.0))


func test_ray_parallel_to_ground_misses() -> void:
	assert_null(InputMathScript.ray_to_ground(Vector3(0.0, 5.0, 0.0), Vector3.RIGHT))


func test_ray_pointing_away_misses() -> void:
	assert_null(InputMathScript.ray_to_ground(Vector3(0.0, 5.0, 0.0), Vector3.UP))


func test_joystick_inside_deadzone_is_zero() -> void:
	assert_eq(InputMathScript.joystick_output(Vector2(5.0, 0.0), 100.0, 0.15), Vector2.ZERO)


func test_joystick_full_deflection_is_one() -> void:
	var out: Vector2 = InputMathScript.joystick_output(Vector2(0.0, 100.0), 100.0, 0.15)
	assert_almost_eq(out.length(), 1.0)
	assert_almost_eq(out.y, 1.0)


func test_joystick_beyond_radius_is_clamped() -> void:
	var out: Vector2 = InputMathScript.joystick_output(Vector2(300.0, 0.0), 100.0, 0.15)
	assert_almost_eq(out.x, 1.0)


func test_joystick_deadzone_is_rescaled() -> void:
	# Halfway between deadzone edge and full deflection -> 0.5 output.
	var out: Vector2 = InputMathScript.joystick_output(Vector2(57.5, 0.0), 100.0, 0.15)
	assert_almost_eq(out.x, 0.5, 0.001)


func test_joystick_zero_radius_is_zero() -> void:
	assert_eq(InputMathScript.joystick_output(Vector2(10.0, 0.0), 0.0, 0.15), Vector2.ZERO)
