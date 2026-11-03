class_name DecoyExecution
extends AbilityExecution

var _data: DecoyAbilityData


func _init(p_context: CastContext, data: DecoyAbilityData) -> void:
	super(p_context)
	_data = data


func start() -> void:
	finished = true
	if _data.decoy_scene == null:
		push_error("DecoyAbilityData '%s' has no decoy_scene." % _data.id)
		return
	var map: RID = context.caster.get_world_3d().navigation_map
	var wanted: Vector3 = context.origin()
	if _data.targeting == AbilityData.Targeting.POINT:
		wanted = context.aim_point(_data.get_range(context.stats))
	var point: Vector3 = NavigationServer3D.map_get_closest_point(map, wanted)
	var decoy: Decoy = _data.decoy_scene.instantiate() as Decoy
	var hp: float = _data.hp_scaling.evaluate(context.stats) if _data.hp_scaling != null else 100.0
	decoy.configure(hp, _data.lifetime * AbilityData.duration_scale(context.stats))
	decoy.position = point
	context.caster.get_parent().add_child(decoy)
