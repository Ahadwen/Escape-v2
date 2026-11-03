extends "res://tests/framework/test_case.gd"

const EnemyBrainScript := preload("res://enemies/enemy_brain.gd")
const TargetableScript := preload("res://actors/components/targetable.gd")


func test_no_flank_offset_when_close() -> void:
	var goal: Vector3 = Vector3(5, 0, 0)
	var point: Vector3 = EnemyBrainScript.flank_point(Vector3(9, 0, 0), goal, 1.0, 4.0)
	assert_eq(point, goal)


func test_zero_flank_angle_approaches_from_enemy_side() -> void:
	var goal: Vector3 = Vector3.ZERO
	var point: Vector3 = EnemyBrainScript.flank_point(Vector3(20, 0, 0), goal, 0.0, 20.0)
	# Offset sits between the goal and the enemy.
	assert_true(point.x > 0.0, "point %s" % point)
	assert_almost_eq(point.z, 0.0, 0.001)


func test_flank_angle_moves_approach_point_sideways() -> void:
	var goal: Vector3 = Vector3.ZERO
	var left: Vector3 = EnemyBrainScript.flank_point(
		Vector3(20, 0, 0), goal, deg_to_rad(60.0), 20.0
	)
	var right: Vector3 = EnemyBrainScript.flank_point(
		Vector3(20, 0, 0), goal, deg_to_rad(-60.0), 20.0
	)
	assert_true(left.z * right.z < 0.0, "left %s right %s" % [left, right])


func test_flank_offset_is_capped() -> void:
	var point: Vector3 = EnemyBrainScript.flank_point(Vector3(100, 0, 0), Vector3.ZERO, 0.5, 100.0)
	assert_almost_eq(point.length(), EnemyBrainScript.MAX_FLANK_OFFSET, 0.001)


func test_targetable_predicts_from_velocity() -> void:
	var body: Node3D = add_to_tree(Node3D.new()) as Node3D
	var targetable: Targetable = TargetableScript.new()
	targetable.body = body
	body.add_child(targetable)
	targetable.velocity = Vector3(4, 0, 0)
	assert_eq(targetable.predicted_position(0.5), Vector3(2, 0, 0))
