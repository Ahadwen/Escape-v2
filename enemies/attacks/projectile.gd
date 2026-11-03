class_name Projectile
extends Node3D
## A straight-line shot. Stops at walls; hits the first player-faction target
## it touches.

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
	var to: Vector3 = from + velocity * delta * EnemyTime.scale()
	var stop: Vector3 = AttackUtils.ray_to_wall(get_world_3d(), from, to)
	global_position = stop
	for target: Targetable in AttackUtils.player_targets(get_tree()):
		if (
			AttackUtils.point_segment_distance_flat(target.world_position(), from, stop)
			<= radius + TARGET_RADIUS
		):
			AttackUtils.damage(target, damage_amount, damage_type, _live_source())
			queue_free()
			return
	if not stop.is_equal_approx(to):
		queue_free()


## The attacker, or null if it has despawned since (attacks outlive them).
func _live_source() -> Node:
	return source if is_instance_valid(source) else null
