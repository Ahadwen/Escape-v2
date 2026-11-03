class_name HoldMovement
extends MovementOverride
## Holds the actor in place for a duration (e.g. while parrying). Like any
## override, it blocks normal movement and movement abilities while active.

var remaining: float


func _init(duration: float) -> void:
	remaining = duration


func compute_velocity(delta: float) -> Vector3:
	remaining -= delta
	if remaining <= 0.0:
		finished = true
	return Vector3.ZERO
