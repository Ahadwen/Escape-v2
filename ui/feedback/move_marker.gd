class_name MoveMarker
extends Node3D
## Brief ring on the ground where a move order was issued.

@export var color: Color = Color(0.45, 1.0, 0.55)
@export var duration: float = 0.35

var _tween: Tween


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	var ring: TorusMesh = TorusMesh.new()
	ring.inner_radius = 0.28
	ring.outer_radius = 0.38
	ring.material = material
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = ring
	mesh_instance.scale = Vector3(1.0, 0.15, 1.0)
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh_instance)
	visible = false


func show_at(point: Vector3) -> void:
	global_position = point + Vector3.UP * 0.05
	visible = true
	if _tween != null:
		_tween.kill()
	scale = Vector3.ONE * 1.4
	_tween = create_tween()
	var shrink: PropertyTweener = _tween.tween_property(self, "scale", Vector3.ONE * 0.6, duration)
	shrink.set_ease(Tween.EASE_OUT)
	shrink.set_trans(Tween.TRANS_CUBIC)
	_tween.tween_callback(hide)
