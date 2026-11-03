class_name GroundStrike
extends Node3D
## Artillery impact: a ring telegraphs the area while a fill grows to it, then
## it detonates. Optionally leaves a lingering zone that keeps damaging.

var radius: float = 2.5
var wind_up: float = 1.3
var damage_amount: float = 40.0
var damage_type: DamageEvent.DamageType = DamageEvent.DamageType.PHYSICAL
var source: Node
var linger_duration: float = 0.0
var linger_damage: float = 0.0
var linger_interval: float = 0.5
var color: Color = Color(1.0, 0.5, 0.2)

var _time: float = 0.0
var _detonated: bool = false
var _tick_timer: float = 0.0
var _ring: MeshInstance3D
var _fill: MeshInstance3D
var _fill_material: StandardMaterial3D


func configure(
	center: Vector3,
	p_radius: float,
	p_wind_up: float,
	p_damage: float,
	p_type: DamageEvent.DamageType,
	p_source: Node,
	p_linger_duration: float = 0.0,
	p_linger_damage: float = 0.0,
	p_linger_interval: float = 0.5
) -> void:
	position = Vector3(center.x, center.y + 0.04, center.z)
	radius = p_radius
	wind_up = p_wind_up
	damage_amount = p_damage
	damage_type = p_type
	source = p_source
	linger_duration = p_linger_duration
	linger_damage = p_linger_damage
	linger_interval = p_linger_interval


func _ready() -> void:
	var ring_material: StandardMaterial3D = StandardMaterial3D.new()
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_material.albedo_color = Color(color.r, color.g, color.b, 0.9)
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 0.92
	torus.outer_radius = 1.0
	torus.material = ring_material
	_ring = MeshInstance3D.new()
	_ring.mesh = torus
	_ring.scale = Vector3(radius, 0.05, radius)
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)

	_fill_material = StandardMaterial3D.new()
	_fill_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fill_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_fill_material.albedo_color = Color(color.r, color.g, color.b, 0.35)
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.02
	disc.material = _fill_material
	_fill = MeshInstance3D.new()
	_fill.mesh = disc
	_fill.scale = Vector3(0.01, 1.0, 0.01)
	_fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_fill)


func _physics_process(raw_delta: float) -> void:
	var delta: float = raw_delta * EnemyTime.scale()
	_time += delta
	if not _detonated:
		var t: float = clampf(_time / wind_up, 0.0, 1.0)
		_fill.scale = Vector3(radius * t, 1.0, radius * t)
		if _time >= wind_up:
			_detonate()
		return
	if _time >= wind_up + linger_duration:
		queue_free()
		return
	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = linger_interval
		AttackUtils.damage_in_radius(
			get_tree(), global_position, radius, linger_damage, damage_type, _live_source()
		)


func _detonate() -> void:
	_detonated = true
	_tick_timer = linger_interval
	AttackUtils.damage_in_radius(
		get_tree(), global_position, radius, damage_amount, damage_type, _live_source()
	)
	_ring.visible = false
	_fill.scale = Vector3(radius, 1.0, radius)
	_fill_material.albedo_color = Color(1.0, 0.9, 0.6, 0.85)
	var tween: Tween = create_tween()
	var linger_color: Color = Color(
		color.r, color.g, color.b, 0.28 if linger_duration > 0.0 else 0.0
	)
	tween.tween_property(_fill_material, "albedo_color", linger_color, 0.25)
	if linger_duration <= 0.0:
		tween.tween_callback(queue_free)


## The attacker, or null if it has despawned since (attacks outlive them).
func _live_source() -> Node:
	return source if is_instance_valid(source) else null
