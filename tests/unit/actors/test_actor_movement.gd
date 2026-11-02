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
