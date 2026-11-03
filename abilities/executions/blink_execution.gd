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
	_shockwave(snapped)


func _shockwave(at: Vector3) -> void:
	if context.health == null:
		return
	var strength: float = BlinkAbilityData.shockwave_strength(
		context.health.pool.fraction(), _data.shockwave_hp_threshold
	)
	if strength < 0.0:
		return
	var radius: float = lerpf(_data.shockwave_radius_min, _data.shockwave_radius_max, strength)
	var knockback: float = lerpf(
		_data.shockwave_knockback_min, _data.shockwave_knockback_max, strength
	)
	var slow_duration: float = lerpf(
		_data.shockwave_slow_duration_min, _data.shockwave_slow_duration_max, strength
	)
	var slow: float = _data.shockwave_slow
	AreaEffects.knock_back(
		context.caster.get_tree(),
		at,
		radius,
		knockback,
		func() -> StatusEffect: return SlowEffect.new(slow, slow_duration, &"blink_shockwave")
	)


func _is_walkable(point: Vector3) -> bool:
	var closest: Vector3 = NavigationServer3D.map_get_closest_point(_map, point)
	var flat_gap: float = Vector2(closest.x - point.x, closest.z - point.z).length()
	return flat_gap <= _data.walkable_tolerance and absf(closest.y - point.y) < 1.0
