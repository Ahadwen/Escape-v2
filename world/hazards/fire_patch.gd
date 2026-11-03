class_name FirePatch
extends Node3D
## Burning ground. Grows in over a moment (so it's never a surprise under
## your feet), damages the player while touched, then burns out.

@export var radius: float = 2.2
@export var lifetime: float = 12.0
@export var grow_time: float = 0.8
@export var damage: float = 5.0
@export var touch_interval: float = 0.35

var _age: float = 0.0
var _touch_timer: float = 0.0
var _body: MeshInstance3D
var _ring: MeshInstance3D
var _material: StandardMaterial3D


## Call before adding to the tree.
func configure(p_radius: float, p_lifetime: float, p_damage: float) -> void:
	radius = p_radius
	lifetime = p_lifetime
	damage = p_damage


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color = Color(1.0, 0.45, 0.1, 0.55)
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.04
	disc.material = _material
	_body = MeshInstance3D.new()
	_body.mesh = disc
	_body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_body)
	var ring_material: StandardMaterial3D = StandardMaterial3D.new()
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_material.albedo_color = Color(0.25, 0.05, 0.03, 0.9)
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 0.9
	torus.outer_radius = 1.05
	torus.material = ring_material
	_ring = MeshInstance3D.new()
	_ring.mesh = torus
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.scale = Vector3(radius, 0.05, radius)
	add_child(_ring)
	_body.scale = Vector3(0.01, 1.0, 0.01)
	position.y += 0.05


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	var grown: float = clampf(_age / grow_time, 0.0, 1.0)
	var fade: float = clampf((lifetime - _age) / 1.0, 0.0, 1.0)
	var pulse: float = 0.85 + 0.15 * sin(_age * 6.0)
	_body.scale = Vector3(radius * grown, 1.0, radius * grown)
	_material.albedo_color.a = 0.55 * pulse * fade
	if grown < 1.0:
		return
	_touch_timer -= delta
	if _touch_timer > 0.0:
		return
	if (
		AttackUtils.damage_in_radius(
			get_tree(), global_position, radius, damage, DamageEvent.DamageType.ELEMENTAL, null
		)
		> 0
	):
		_touch_timer = touch_interval
