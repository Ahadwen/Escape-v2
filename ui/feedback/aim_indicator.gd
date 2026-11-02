class_name AimIndicator
extends Node3D
## Ground decal-style preview of where an ability will go: a line for
## direction abilities, a ring for point abilities.

@export var color: Color = Color(0.55, 0.8, 1.0, 0.6)
@export var line_width: float = 0.35

var _line: MeshInstance3D
var _ring: MeshInstance3D


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color

	var box: BoxMesh = BoxMesh.new()
	# Unit length along -Z, starting at the origin; scaled to the range.
	box.size = Vector3(line_width, 0.02, 1.0)
	box.material = material
	_line = MeshInstance3D.new()
	_line.mesh = box
	_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_line)

	var ring: TorusMesh = TorusMesh.new()
	ring.inner_radius = 0.85
	ring.outer_radius = 1.0
	ring.material = material
	_ring = MeshInstance3D.new()
	_ring.mesh = ring
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)

	clear()


func show_direction(origin: Vector3, direction: Vector3, length: float) -> void:
	var flat: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.0001 or length <= 0.0:
		clear()
		return
	visible = true
	_ring.visible = false
	_line.visible = true
	global_position = origin + Vector3.UP * 0.05
	rotation = Vector3(0.0, ActorMovement.yaw_for_direction(flat), 0.0)
	_line.scale = Vector3(1.0, 1.0, length)
	_line.position = Vector3(0.0, 0.0, -length * 0.5)


func show_point(point: Vector3, radius: float) -> void:
	visible = true
	_line.visible = false
	_ring.visible = true
	global_position = point + Vector3.UP * 0.05
	rotation = Vector3.ZERO
	_ring.scale = Vector3(radius, 0.1, radius)


func clear() -> void:
	visible = false
