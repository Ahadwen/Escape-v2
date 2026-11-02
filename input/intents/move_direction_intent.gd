class_name MoveDirectionIntent
extends PlayerIntent
## Move in a world-space direction (analogue stick). Length 0..1 scales speed;
## a zero vector means "stop steering".

var direction: Vector3


func _init(world_direction: Vector3) -> void:
	direction = world_direction
