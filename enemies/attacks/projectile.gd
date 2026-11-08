class_name Projectile
extends Node3D
## A straight-line shot. Stops at walls; hits the first player-faction target
## it touches. Emits `impacted` wherever it ends (target, wall or range).

signal impacted(point: Vector3, target: Targetable)

const GROUP: StringName = &"enemy_projectiles"
## Extra reach so the shot connects with a body, not just its centre point.
const TARGET_RADIUS: float = 0.4

var velocity: Vector3 = Vector3.ZERO
var damage_amount: float = 20.0
var damage_type: DamageEvent.DamageType = DamageEvent.DamageType.PHYSICAL
var source: Node
var radius: float = 0.3
## Safety net only: shots normally fly until they hit a wall or a target.
var lifetime: float = 10.0
var color: Color = Color(1.0, 0.45, 0.25)
## Flies at most this far, then ends (impacted at that point).
var max_distance: float = INF
## Optional weave: the shot swings side to side around its straight line by
## up to this many metres ...
var wave_amplitude: float = 0.0
## ... this many times a second, starting at this phase (radians).
var wave_frequency: float = 1.0
var wave_phase: float = 0.0

var _age: float = 0.0
## Where the shot would be on its straight line (the weave is added to it).
var _base: Vector3
var _has_base: bool = false

var _travelled: float = 0.0


func configure(
	origin: Vector3,
	direction: Vector3,
	speed: float,
	p_damage: float,
	p_type: DamageEvent.DamageType,
	p_source: Node,
	p_radius: float = 0.3
) -> void:
	position = Vector3(origin.x, origin.y + AttackUtils.EYE_HEIGHT, origin.z)
	var flat: Vector3 = Vector3(direction.x, 0.0, direction.z).normalized()
	velocity = flat * speed
	damage_amount = p_damage
	damage_type = p_type
	source = p_source
	radius = p_radius


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.5
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.material = material
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.mesh = sphere
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	var from: Vector3 = global_position
	if not _has_base:
		_base = from - _weave_offset()
		_has_base = true
	var time_scale: float = EnemyTime.scale() * DilationField.projectile_scale_at(from)
	var step: float = minf(velocity.length() * delta * time_scale, max_distance - _travelled)
	_travelled += step
	_age += delta * time_scale
	_base += velocity.normalized() * step
	var to: Vector3 = _base + _weave_offset()
	var stop: Vector3 = AttackUtils.ray_to_wall(get_world_3d(), from, to)
	global_position = stop
	for target: Targetable in AttackUtils.player_targets(get_tree()):
		if AttackUtils.is_phased(target):
			continue
		if (
			AttackUtils.point_segment_distance_flat(target.world_position(), from, stop)
			<= radius + TARGET_RADIUS
		):
			AttackUtils.damage(target, damage_amount, damage_type, _live_source())
			_end(target.world_position(), target)
			return
	if not stop.is_equal_approx(to) or _travelled >= max_distance - 0.001:
		_end(stop, null)


## Sideways offset from the straight line at the shot's current age.
func _weave_offset() -> Vector3:
	if wave_amplitude <= 0.0 or velocity.length_squared() < 0.0001:
		return Vector3.ZERO
	var side: Vector3 = velocity.normalized().cross(Vector3.UP)
	return side * wave_amplitude * sin(TAU * wave_frequency * _age + wave_phase)


func _end(point: Vector3, target: Targetable) -> void:
	impacted.emit(Vector3(point.x, point.y - AttackUtils.EYE_HEIGHT, point.z), target)
	queue_free()


## The attacker, or null if it has despawned since (attacks outlive them).
func _live_source() -> Node:
	return source if is_instance_valid(source) else null
