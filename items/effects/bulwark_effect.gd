class_name BulwarkEffect
extends CardEffect
## K♥: a shield in a cone in front of you blocks hits that come from that
## direction.

@export var arc_degrees: float = 80.0
@export var shield_radius: float = 1.1


func create_instance() -> CardEffectInstance:
	return Instance.new()


## True if `source_direction` (flat, from the player to the attacker) lies
## within the cone around `facing`.
static func is_within_arc(facing: Vector3, source_direction: Vector3, arc_degrees: float) -> bool:
	var f: Vector2 = Vector2(facing.x, facing.z).normalized()
	var s: Vector2 = Vector2(source_direction.x, source_direction.z).normalized()
	if f == Vector2.ZERO or s == Vector2.ZERO:
		return false
	return absf(rad_to_deg(f.angle_to(s))) <= arc_degrees * 0.5


class Instance:
	extends CardEffectInstance

	var _visual: MeshInstance3D

	func on_equip() -> void:
		intercept_damage(_intercept)
		var effect: BulwarkEffect = data as BulwarkEffect
		_visual = MeshInstance3D.new()
		_visual.mesh = _fan_mesh(effect.arc_degrees, effect.shield_radius)
		_visual.position = Vector3(0.0, 0.9, 0.0)
		_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		player.visual.add_child(_visual)

	func on_unequip() -> void:
		if is_instance_valid(_visual):
			_visual.queue_free()

	func _intercept(event: DamageEvent, amount: float) -> float:
		var source: Node3D = event.source as Node3D
		if source == null or not is_instance_valid(source):
			return amount
		var to_source: Vector3 = source.global_position - player.global_position
		var arc: float = (data as BulwarkEffect).arc_degrees
		if BulwarkEffect.is_within_arc(player.movement.get_facing(), to_source, arc):
			return 0.0
		return amount

	static func _fan_mesh(arc_degrees: float, radius: float) -> ArrayMesh:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.albedo_color = Color(0.9, 0.35, 0.4, 0.35)
		var surface: SurfaceTool = SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		surface.set_material(material)
		var segments: int = 12
		var half: float = deg_to_rad(arc_degrees * 0.5)
		for i: int in segments:
			var a: float = lerpf(-half, half, float(i) / segments)
			var b: float = lerpf(-half, half, float(i + 1) / segments)
			surface.add_vertex(Vector3.ZERO)
			surface.add_vertex(Vector3(sin(a), 0.0, -cos(a)) * radius)
			surface.add_vertex(Vector3(sin(b), 0.0, -cos(b)) * radius)
		return surface.commit()
