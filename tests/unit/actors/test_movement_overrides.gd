extends "res://tests/framework/test_case.gd"

const DashMovementScript := preload("res://actors/movement/dash_movement.gd")
const ChargeMovementScript := preload("res://actors/movement/charge_movement.gd")

const DT: float = 1.0 / 60.0


func test_dash_covers_exact_distance() -> void:
	var dash: DashMovement = DashMovementScript.new(Vector3.RIGHT, 5.0, 20.0)
	var travelled: float = 0.0
	for i: int in 200:
		var velocity: Vector3 = dash.compute_velocity(DT)
		if dash.finished:
			break
		travelled += velocity.x * DT
	assert_almost_eq(travelled, 5.0, 0.001)


func test_dash_velocity_is_flat_and_at_speed() -> void:
	var dash: DashMovement = DashMovementScript.new(Vector3(1, 1, 0), 5.0, 20.0)
	var velocity: Vector3 = dash.compute_velocity(DT)
	assert_almost_eq(velocity.y, 0.0)
	assert_almost_eq(velocity.length(), 20.0, 0.001)


func test_dash_with_no_direction_finishes() -> void:
	var dash: DashMovement = DashMovementScript.new(Vector3.ZERO, 5.0, 20.0)
	dash.compute_velocity(DT)
	assert_true(dash.finished)


func test_override_ended_signal_fires_once() -> void:
	var dash: DashMovement = DashMovementScript.new(Vector3.RIGHT, 1.0, 20.0)
	var count: Array[int] = [0]
	dash.ended.connect(func() -> void: count[0] += 1)
	dash.cancel()
	dash.cancel()
	assert_eq(count[0], 1)


func test_charge_accelerates_to_max_speed() -> void:
	var charge: ChargeMovement = ChargeMovementScript.new(
		Vector3.FORWARD, 6.0, 16.0, 8.0, 1.0, 10.0
	)
	var velocity: Vector3 = Vector3.ZERO
	for i: int in 300:
		velocity = charge.compute_velocity(DT)
	assert_almost_eq(velocity.length(), 16.0, 0.001)


func test_charge_times_out() -> void:
	var charge: ChargeMovement = ChargeMovementScript.new(Vector3.FORWARD, 6.0, 16.0, 8.0, 1.0, 0.5)
	for i: int in 40:
		charge.compute_velocity(DT)
	assert_true(charge.finished)


func test_charge_turn_rate_is_limited() -> void:
	var turn_rate: float = deg_to_rad(90.0)
	var charge: ChargeMovement = ChargeMovementScript.new(
		Vector3.FORWARD, 6.0, 16.0, 0.0, turn_rate, 10.0
	)
	charge.steer_direction = Vector3.BACK
	charge.compute_velocity(1.0)
	# One second at 90°/s turns forward into a side direction, not backward.
	assert_almost_eq(absf(charge.direction.x), 1.0, 0.001)
	assert_almost_eq(charge.direction.z, 0.0, 0.001)


func test_charge_without_steer_goes_straight() -> void:
	var charge: ChargeMovement = ChargeMovementScript.new(Vector3.RIGHT, 6.0, 16.0, 0.0, 1.0, 10.0)
	charge.compute_velocity(0.5)
	assert_almost_eq(charge.direction.x, 1.0, 0.001)


func test_dash_decay_slows_only_the_final_part() -> void:
	var dash: DashMovement = DashMovementScript.new(Vector3.RIGHT, 10.0, 20.0, 0.2, 0.25)
	assert_almost_eq(dash.current_speed(), 20.0)
	dash.remaining_distance = 2.0
	assert_almost_eq(dash.current_speed(), 20.0)
	dash.remaining_distance = 1.0
	assert_almost_eq(dash.current_speed(), 12.5)
	dash.remaining_distance = 0.0
	assert_almost_eq(dash.current_speed(), 5.0)


func test_decaying_dash_still_covers_full_distance() -> void:
	var dash: DashMovement = DashMovementScript.new(Vector3.RIGHT, 10.0, 20.0, 0.2, 0.25)
	var travelled: float = 0.0
	for i: int in 600:
		var velocity: Vector3 = dash.compute_velocity(DT)
		if dash.finished:
			break
		travelled += velocity.x * DT
	assert_almost_eq(travelled, 10.0, 0.001)
