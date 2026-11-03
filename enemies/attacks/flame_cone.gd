class_name FlameCone
extends Node3D
## An expanding arc of flame (Inferno gunner): a band that travels outward in
## a narrow cone, hitting each player-faction target once as it passes.

var origin: Vector3
var direction: Vector3
var half_angle: float = deg_to_rad(7.5)
var speed: float = 16.0
var max_radius: float = 18.0
var band: float = 1.2
var damage_amount: float = 20.0
var source: Node

var _radius: float = 0.5
var _hit: Array[Targetable] = []
var _mesh: MeshInstance3D
var _material: StandardMaterial3D


func configure(
	p_origin: Vector3, p_direction: Vector3, p_damage: float, p_source: Node, p_max_radius: float
) -> void:
	origin = Vector3(p_origin.x, p_origin.y, p_origin.z)
	direction = Vector3(p_direction.x, 0.0, p_direction.z).normalized()
	damage_amount = p_damage
	source = p_source
	max_radius = p_max_radius


## True if `point` is inside the band at `radius` of a cone from `from`.
static func in_band(
	from: Vector3, dir: Vector3, angle: float, radius: float, width: float, point: Vector3
) -> bool:
	var offset: Vector2 = Vector2(point.x - from.x, point.z - from.z)
	var distance: float = offset.length()
	if distance < radius - width * 0.5 or distance > radius + width * 0.5:
		return false
	return absf(Vector2(dir.x, dir.z).angle_to(offset)) <= angle + 0.15


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	position = origin + Vector3.UP * 0.6
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.albedo_color = Color(1.0, 0.5, 0.15, 0.8)
	_mesh = MeshInstance3D.new()
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)
	rotation.y = ActorMovement.yaw_for_direction(direction)


func _physics_process(delta: float) -> void:
	_radius += (
		speed
		* delta
		* EnemyTime.scale()
		* DilationField.projectile_scale_at(origin + direction * _radius)
	)
	if _radius >= max_radius:
		queue_free()
		return
	_mesh.mesh = _arc_mesh(_radius, band, half_angle)
	_material.albedo_color.a = 0.8 * (1.0 - _radius / max_radius) + 0.2
	for target: Targetable in AttackUtils.player_targets(get_tree()):
		if target in _hit or AttackUtils.is_phased(target):
			continue
		if in_band(origin, direction, half_angle, _radius, band, target.world_position()):
			_hit.append(target)
			AttackUtils.damage(
				target,
				damage_amount,
				DamageEvent.DamageType.ELEMENTAL,
				source if is_instance_valid(source) else null
			)


func _arc_mesh(radius: float, width: float, angle: float) -> ArrayMesh:
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(_material)
	var inner: float = maxf(radius - width * 0.5, 0.0)
	var outer: float = radius + width * 0.5
	var segments: int = 6
	for i: int in segments:
		var a: float = lerpf(-angle, angle, float(i) / segments)
		var b: float = lerpf(-angle, angle, float(i + 1) / segments)
		var ia: Vector3 = Vector3(sin(a), 0.0, -cos(a)) * inner
		var oa: Vector3 = Vector3(sin(a), 0.0, -cos(a)) * outer
		var ib: Vector3 = Vector3(sin(b), 0.0, -cos(b)) * inner
		var ob: Vector3 = Vector3(sin(b), 0.0, -cos(b)) * outer
		surface.add_vertex(ia)
		surface.add_vertex(oa)
		surface.add_vertex(ob)
		surface.add_vertex(ia)
		surface.add_vertex(ob)
		surface.add_vertex(ib)
	return surface.commit()
