class_name LaserBeam
extends Node3D
## The firing half of a laser: damages everything along the segment once,
## then fades. (The warning line is drawn beforehand by whoever fires it.)

var from_point: Vector3
var to_point: Vector3
var half_width: float = 0.3
var duration: float = 0.25
var damage_amount: float = 50.0
var damage_type: DamageEvent.DamageType = DamageEvent.DamageType.ELEMENTAL
var source: Node
var color: Color = Color(1.0, 0.3, 0.9)

var _material: StandardMaterial3D


func configure(
	p_from: Vector3,
	p_to: Vector3,
	p_half_width: float,
	p_damage: float,
	p_type: DamageEvent.DamageType,
	p_source: Node,
	p_duration: float = 0.25
) -> void:
	from_point = p_from
	to_point = p_to
	half_width = p_half_width
	damage_amount = p_damage
	damage_type = p_type
	source = p_source
	duration = p_duration


func _ready() -> void:
	var length: float = Vector2(to_point.x - from_point.x, to_point.z - from_point.z).length()
	var direction: Vector3 = Vector3(to_point.x - from_point.x, 0.0, to_point.z - from_point.z)
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color = color
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(half_width * 2.0, 0.25, maxf(length, 0.01))
	box.material = _material
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.mesh = box
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	position = (from_point + to_point) * 0.5 + Vector3.UP * AttackUtils.EYE_HEIGHT
	if direction.length_squared() > 0.0001:
		rotation = Vector3(0.0, ActorMovement.yaw_for_direction(direction), 0.0)
	AttackUtils.damage_on_segment(
		get_tree(), from_point, to_point, half_width, damage_amount, damage_type, _live_source()
	)
	var tween: Tween = create_tween()
	tween.tween_property(_material, "albedo_color", Color(color.r, color.g, color.b, 0.0), duration)
	tween.tween_callback(queue_free)


## The attacker, or null if it has despawned since (attacks outlive them).
func _live_source() -> Node:
	return source if is_instance_valid(source) else null
