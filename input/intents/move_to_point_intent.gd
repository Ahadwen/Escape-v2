class_name MoveToPointIntent
extends PlayerIntent
## Path to a point on the ground (PC right-click).

var point: Vector3


func _init(target_point: Vector3) -> void:
	point = target_point
