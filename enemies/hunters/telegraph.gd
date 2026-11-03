class_name Telegraph
extends Node3D
## A ground warning for a hunter's attack: a faint outline of the area, plus a
## fill that grows as the attack winds up, so the timing is readable.
## Shapes: line (width x length), circle, cone.

enum Shape { LINE, CIRCLE, CONE }

const OUTLINE_ALPHA: float = 0.22
const FILL_ALPHA: float = 0.5

var color: Color = Color(1.0, 0.25, 0.2)

var _outline: MeshInstance3D
var _fill: MeshInstance3D
var _outline_material: StandardMaterial3D
var _fill_material: StandardMaterial3D
var _shape: Shape = Shape.LINE


func _ready() -> void:
	top_level = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_outline_material = _material(OUTLINE_ALPHA)
	_fill_material = _material(FILL_ALPHA)
	_outline = MeshInstance3D.new()
	_outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_outline)
	_fill = MeshInstance3D.new()
	_fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_fill.position.y = 0.01
	add_child(_fill)
	clear()


func show_line(origin: Vector3, direction: Vector3, length: float, width: float) -> void:
	_place(origin, direction)
	_set_meshes(_quad(width, length))
	_shape = Shape.LINE
	set_progress(0.0)


func show_circle(center: Vector3, radius: float) -> void:
	_place(center, Vector3.FORWARD)
	_set_meshes(_fan(radius, 360.0))
	_shape = Shape.CIRCLE
	set_progress(0.0)


func show_cone(origin: Vector3, direction: Vector3, radius: float, angle_degrees: float) -> void:
	_place(origin, direction)
	_set_meshes(_fan(radius, angle_degrees))
	_shape = Shape.CONE
	set_progress(0.0)


## 0 = just started winding up, 1 = about to hit.
func set_progress(progress: float) -> void:
	var p: float = clampf(progress, 0.02, 1.0)
	_fill.scale = Vector3(1.0, 1.0, p) if _shape == Shape.LINE else Vector3(p, 1.0, p)


func clear() -> void:
	visible = false


func _place(at: Vector3, direction: Vector3) -> void:
	visible = true
	global_position = Vector3(at.x, at.y + 0.06, at.z)
	var flat: Vector3 = Vector3(direction.x, 0.0, direction.z)
	rotation = (
		Vector3(0.0, ActorMovement.yaw_for_direction(flat), 0.0)
		if flat != Vector3.ZERO
		else Vector3.ZERO
	)


func _set_meshes(mesh: ArrayMesh) -> void:
	_outline.mesh = mesh
	_outline.material_override = _outline_material
	_fill.mesh = mesh
	_fill.material_override = _fill_material


func _material(alpha: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(color.r, color.g, color.b, alpha)
	return material


## A rectangle from the origin forward (-Z) `length`, `width` wide.
static func _quad(width: float, length: float) -> ArrayMesh:
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w: float = width * 0.5
	var a: Vector3 = Vector3(-w, 0, 0)
	var b: Vector3 = Vector3(w, 0, 0)
	var c: Vector3 = Vector3(w, 0, -length)
	var d: Vector3 = Vector3(-w, 0, -length)
	for v: Vector3 in [a, b, c, a, c, d]:
		surface.add_vertex(v)
	return surface.commit()


## A fan (cone or full circle) around the origin, centred on forward (-Z).
static func _fan(radius: float, angle_degrees: float) -> ArrayMesh:
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments: int = maxi(8, roundi(angle_degrees / 10.0))
	var half: float = deg_to_rad(angle_degrees * 0.5)
	for i: int in segments:
		var a0: float = lerpf(-half, half, float(i) / segments)
		var a1: float = lerpf(-half, half, float(i + 1) / segments)
		surface.add_vertex(Vector3.ZERO)
		surface.add_vertex(Vector3(sin(a0), 0.0, -cos(a0)) * radius)
		surface.add_vertex(Vector3(sin(a1), 0.0, -cos(a1)) * radius)
	return surface.commit()
