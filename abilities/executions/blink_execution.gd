class_name BlinkExecution
extends AbilityExecution

## Emitted after teleporting, with the landing position. (M3: shockwave.)
signal landed(position: Vector3)

var _data: BlinkAbilityData
var _map: RID


func _init(p_context: CastContext, data: BlinkAbilityData) -> void:
	super(p_context)
	_data = data


func start() -> void:
	finished = true
	_map = context.caster.get_world_3d().navigation_map
	var direction: Vector3 = context.aim_direction()
	var landing: Variant = BlinkLanding.find(
		context.origin(),
		direction,
		_data.get_range(context.stats),
		_is_walkable,
		0.1,
		_data.max_overshoot
	)
	if landing == null:
		return
	var point: Vector3 = landing
	var snapped: Vector3 = NavigationServer3D.map_get_closest_point(_map, point)
	context.movement.teleport(snapped, direction)
	landed.emit(snapped)


func _is_walkable(point: Vector3) -> bool:
	var closest: Vector3 = NavigationServer3D.map_get_closest_point(_map, point)
	var flat_gap: float = Vector2(closest.x - point.x, closest.z - point.z).length()
	return flat_gap <= _data.walkable_tolerance and absf(closest.y - point.y) < 1.0
