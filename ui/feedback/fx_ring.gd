class_name FxRing
extends Node3D
## A one-shot ring on the ground that expands and fades, then frees itself.

var color: Color = Color(1, 1, 1, 0.8)
var start_radius: float = 0.5
var end_radius: float = 3.0
var duration: float = 0.3

var _material: StandardMaterial3D
var _mesh: MeshInstance3D


static func spawn(
	parent: Node,
	at: Vector3,
	p_color: Color,
	from_radius: float,
	to_radius: float,
	p_duration: float
) -> FxRing:
	var ring: FxRing = FxRing.new()
	ring.color = p_color
	ring.start_radius = from_radius
	ring.end_radius = to_radius
	ring.duration = p_duration
	ring.position = at + Vector3.UP * 0.06
	parent.add_child(ring)
	return ring


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color = color
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 0.85
	torus.outer_radius = 1.0
	torus.material = _material
	_mesh = MeshInstance3D.new()
	_mesh.mesh = torus
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh.scale = Vector3(start_radius, 0.08, start_radius)
	add_child(_mesh)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(_mesh, "scale", Vector3(end_radius, 0.08, end_radius), duration)
	tween.tween_property(_material, "albedo_color", Color(color.r, color.g, color.b, 0.0), duration)
	tween.chain().tween_callback(queue_free)
