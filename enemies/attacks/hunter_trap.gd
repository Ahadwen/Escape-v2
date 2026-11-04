class_name HunterTrap
extends Node3D
## A visible snare on the ground (Trapper). Arms after a moment; the first
## player-faction target to step on it is rooted (and lightly hurt), then it's
## gone. Expires on its own.

var radius: float = 0.9
var arm_time: float = 0.35
var lifetime: float = 8.0
var root_time: float = 1.0
var damage_amount: float = 10.0
var damage_type: DamageEvent.DamageType = DamageEvent.DamageType.PHYSICAL
var source: Node
var color: Color = Color(0.95, 0.55, 0.15)

var _time: float = 0.0
var _material: StandardMaterial3D


func _ready() -> void:
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color = Color(color.r, color.g, color.b, 0.35)
	var ring: TorusMesh = TorusMesh.new()
	ring.inner_radius = radius * 0.7
	ring.outer_radius = radius
	ring.material = _material
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.mesh = ring
	mesh.scale = Vector3(1.0, 0.15, 1.0)
	mesh.position.y = 0.05
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)


func is_armed() -> bool:
	return _time >= arm_time


func _physics_process(raw_delta: float) -> void:
	_time += raw_delta * EnemyTime.scale()
	if _time >= lifetime:
		queue_free()
		return
	if not is_armed():
		return
	_material.albedo_color = Color(color.r, color.g, color.b, 0.9)
	for target: Targetable in AttackUtils.player_targets(get_tree()):
		if AttackUtils.is_phased(target) or target.flat_distance_to(global_position) > radius:
			continue
		AttackUtils.damage(target, damage_amount, damage_type, _live_source(), false)
		AttackUtils.apply_status(target, RootEffect.new(root_time, &"snared"))
		queue_free()
		return


func _live_source() -> Node:
	return source if is_instance_valid(source) else null
