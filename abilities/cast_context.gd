class_name CastContext
extends RefCounted
## Everything an ability execution needs about its caster. Aim is updated
## while the execution runs, so sustained abilities can be steered.

var caster: Node3D
var movement: ActorMovement
var stats: StatBlock
var aim: AimData


func _init(p_caster: Node3D, p_movement: ActorMovement, p_stats: StatBlock, p_aim: AimData) -> void:
	caster = p_caster
	movement = p_movement
	stats = p_stats
	aim = p_aim if p_aim != null else AimData.none()


func origin() -> Vector3:
	return caster.global_position


## Aimed direction, or the caster's facing if there's no aim.
func aim_direction() -> Vector3:
	if aim.direction != Vector3.ZERO:
		return aim.direction
	if movement != null:
		return movement.get_facing()
	var forward: Vector3 = -caster.global_basis.z
	return Vector3(forward.x, 0.0, forward.z).normalized()


## Aimed ground point, clamped to max_range from the caster.
func aim_point(max_range: float) -> Vector3:
	var from: Vector3 = origin()
	var offset: Vector3
	if aim.has_point:
		offset = Vector3(aim.point.x - from.x, 0.0, aim.point.z - from.z).limit_length(max_range)
	else:
		offset = aim_direction() * max_range * (aim.strength if not aim.is_none() else 1.0)
	return from + offset
