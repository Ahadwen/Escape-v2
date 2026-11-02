class_name AimData
extends RefCounted
## Where the player is aiming, independent of device. Input schemes produce
## it; abilities interpret it according to their targeting type.

## Flat, normalised world direction from the caster, or zero for "no aim"
## (abilities then fall back to the caster's facing).
var direction: Vector3 = Vector3.ZERO
## 0..1. For stick aiming, how far the stick is pushed.
var strength: float = 0.0
## An exact ground point (mouse cursor). Only valid if has_point.
var point: Vector3 = Vector3.ZERO
var has_point: bool = false


static func none() -> AimData:
	return AimData.new()


static func from_point(origin: Vector3, ground_point: Vector3) -> AimData:
	var aim: AimData = AimData.new()
	var offset: Vector3 = Vector3(ground_point.x - origin.x, 0.0, ground_point.z - origin.z)
	if offset.length_squared() > 0.0001:
		aim.direction = offset.normalized()
		aim.strength = 1.0
	aim.point = ground_point
	aim.has_point = true
	return aim


static func from_direction(world_direction: Vector3, p_strength: float = 1.0) -> AimData:
	var aim: AimData = AimData.new()
	var flat: Vector3 = Vector3(world_direction.x, 0.0, world_direction.z)
	if flat.length_squared() > 0.0001:
		aim.direction = flat.normalized()
		aim.strength = clampf(p_strength, 0.0, 1.0)
	return aim


func is_none() -> bool:
	return direction == Vector3.ZERO and not has_point
