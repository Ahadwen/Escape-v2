extends "res://tests/framework/test_case.gd"

const ActorMovementScript := preload("res://actors/components/actor_movement.gd")


func _facing_after_yaw(yaw: float) -> Vector3:
	return Basis(Vector3.UP, yaw) * Vector3.FORWARD


func test_yaw_faces_each_cardinal_direction() -> void:
	for direction: Vector3 in [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]:
		var facing: Vector3 = _facing_after_yaw(ActorMovementScript.yaw_for_direction(direction))
		assert_almost_eq(facing.dot(direction), 1.0, 0.001, "facing %s" % direction)


func test_yaw_faces_diagonal() -> void:
	var direction: Vector3 = Vector3(1.0, 0.0, 1.0).normalized()
	var facing: Vector3 = _facing_after_yaw(ActorMovementScript.yaw_for_direction(direction))
	assert_almost_eq(facing.dot(direction), 1.0, 0.001)


func test_waypoint_reached_ignores_height() -> void:
	var path: PackedVector3Array = PackedVector3Array([Vector3(0, 0.25, 0), Vector3(5, 0.25, 0)])
	var index: int = ActorMovementScript.next_waypoint_index(path, 0, Vector3.ZERO, 0.1)
	assert_eq(index, 1)


func test_waypoint_not_reached_when_far() -> void:
	var path: PackedVector3Array = PackedVector3Array([Vector3(2, 0, 0)])
	assert_eq(ActorMovementScript.next_waypoint_index(path, 0, Vector3.ZERO, 0.1), 0)


func test_all_waypoints_reached_returns_size() -> void:
	var path: PackedVector3Array = PackedVector3Array([Vector3(0.05, 0, 0), Vector3(0, 0, 0.05)])
	assert_eq(ActorMovementScript.next_waypoint_index(path, 0, Vector3.ZERO, 0.1), 2)
