class_name DilationField
extends RefCounted
## Bubbles around the player (10♣ Dilation) that slow enemy projectiles and
## lengthen ranged enemies' wind-ups nearby. Registered by card effects.


class Field:
	var center: Node3D
	var radius: float
	var projectile_scale: float
	var wind_up_scale: float


static var _fields: Array[Field] = []


static func add(
	center: Node3D, radius: float, projectile_scale: float, wind_up_scale: float
) -> Field:
	var field: Field = Field.new()
	field.center = center
	field.radius = radius
	field.projectile_scale = projectile_scale
	field.wind_up_scale = wind_up_scale
	_fields.append(field)
	return field


static func remove(field: Field) -> void:
	_fields.erase(field)


static func clear() -> void:
	_fields.clear()


static func projectile_scale_at(point: Vector3) -> float:
	var result: float = 1.0
	for field: Field in _fields:
		if _inside(field, point):
			result = minf(result, field.projectile_scale)
	return result


static func wind_up_scale_at(point: Vector3) -> float:
	var result: float = 1.0
	for field: Field in _fields:
		if _inside(field, point):
			result = maxf(result, field.wind_up_scale)
	return result


static func _inside(field: Field, point: Vector3) -> bool:
	if not is_instance_valid(field.center):
		return false
	var c: Vector3 = field.center.global_position
	return Vector2(point.x - c.x, point.z - c.z).length() <= field.radius
