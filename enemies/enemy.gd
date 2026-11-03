class_name Enemy
extends CharacterBody3D
## An enemy. Can't be killed: it exists for a limited lifetime, flickers as a
## warning, then despawns. Behaviour comes from the brain its EnemyData creates.
## Handles what every enemy shares: size, contact damage, speeding up with age.

signal despawned(enemy: Enemy)

const GROUP: StringName = &"enemies"
## Speed of knockbacks applied to enemies, metres per second.
const KNOCKBACK_SPEED: float = 20.0
## Contact reach beyond the collision radius.
const CONTACT_MARGIN: float = 0.55
const AGE_SPEED_SOURCE: StringName = &"age"
const THREAT_SPEED_SOURCE: StringName = &"threat"
const AGE_SPEED_REFRESH: float = 0.5

@export var data: EnemyData
## Set by whoever spawns the enemy (from threat) before it enters the tree.
var damage_multiplier: float = 1.0
var speed_multiplier: float = 1.0

var brain: EnemyBrain
var lifetime: float = 0.0
var lifetime_remaining: float = 0.0
## Collision radius after body_scale.
var body_radius: float = 0.45

var _despawning: bool = false
var _contact_cooldowns: Dictionary[int, float] = {}
var _age_modifier: StatModifier
var _age_refresh: float = 0.0

@onready var stats: StatsComponent = $StatsComponent
@onready var movement: ActorMovement = $ActorMovement
@onready var status: StatusEffectHost = $StatusEffectHost
@onready var visual: Node3D = $Visual
## Animatable pivot inside Visual (Visual itself is turned by movement).
@onready var model: Node3D = $Visual/Model
@onready var body_mesh: MeshInstance3D = $Visual/Model/Body
@onready var collision: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	add_to_group(GROUP)
	if data == null:
		push_error("Enemy spawned without EnemyData.")
		queue_free()
		return
	stats.initialize(data.get_base_stats())
	if not is_equal_approx(speed_multiplier, 1.0):
		stats.block.add_modifier(
			StatModifier.new(
				StatIds.MOVE_SPEED,
				StatModifier.Type.PERCENT_MULT,
				speed_multiplier - 1.0,
				THREAT_SPEED_SOURCE
			)
		)
	_apply_size()
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = data.color
	body_mesh.material_override = material
	lifetime = randf_range(data.lifetime_min, data.lifetime_max)
	lifetime_remaining = lifetime
	brain = data.create_brain()
	brain.name = "Brain"
	brain.setup(self)
	add_child(brain)


func _physics_process(delta: float) -> void:
	if _despawning or brain == null:
		return
	lifetime_remaining -= delta
	if lifetime_remaining <= 0.0:
		despawn()
		return
	_update_age_speed(delta)
	if status.is_stunned():
		movement.stop()
	else:
		brain.tick(delta)
	_contact_damage(delta)


func _process(_delta: float) -> void:
	if data == null or _despawning:
		return
	# Flicker during the despawn warning, faster as time runs out.
	if lifetime_remaining <= data.despawn_warning:
		var rate: float = lerpf(4.0, 12.0, 1.0 - lifetime_remaining / data.despawn_warning)
		visual.visible = fmod(lifetime_remaining * rate, 1.0) > 0.35
	else:
		visual.visible = true


func is_despawning() -> bool:
	return _despawning


func despawn() -> void:
	if _despawning:
		return
	_despawning = true
	despawned.emit(self)
	queue_free()


## 0 when spawned, 1 at the end of its life.
func age_fraction() -> float:
	return 1.0 - lifetime_remaining / lifetime if lifetime > 0.0 else 0.0


## Pushes the enemy away along a direction. Interrupts what it was doing.
func apply_knockback(direction: Vector3, distance: float) -> void:
	movement.start_override(DashMovement.new(direction, distance, KNOCKBACK_SPEED))
	if brain != null:
		brain.interrupt()


func apply_status(effect: StatusEffect) -> void:
	status.apply(effect)
	if effect.stuns and brain != null:
		brain.interrupt()


## Damage this enemy actually deals for a base amount from its data.
func scaled_damage(base: float) -> float:
	return base * damage_multiplier


## Spawns a child enemy (e.g. a brood's mite) that inherits this enemy's
## threat scaling. Returns it.
func spawn_minion(minion_data: EnemyData, at: Vector3, scene: PackedScene) -> Enemy:
	var minion: Enemy = scene.instantiate() as Enemy
	minion.data = minion_data
	minion.damage_multiplier = damage_multiplier
	minion.speed_multiplier = speed_multiplier
	minion.position = at
	get_parent().add_child(minion)
	return minion


## Where attacks (projectiles, beams) leave from.
func attack_origin() -> Vector3:
	return global_position


func _apply_size() -> void:
	var size: Vector3 = data.body_scale
	model.scale = size
	var capsule: CapsuleShape3D = collision.shape.duplicate() as CapsuleShape3D
	capsule.radius *= maxf(size.x, size.z)
	capsule.height = maxf(capsule.height * size.y, capsule.radius * 2.0)
	collision.shape = capsule
	collision.position.y = capsule.height * 0.5
	body_radius = capsule.radius


func _update_age_speed(delta: float) -> void:
	_age_refresh -= delta
	if _age_refresh > 0.0 or data.speed_gain_over_life <= 0.0:
		return
	_age_refresh = AGE_SPEED_REFRESH
	if _age_modifier != null:
		stats.block.remove_modifier(_age_modifier)
	_age_modifier = StatModifier.new(
		StatIds.MOVE_SPEED,
		StatModifier.Type.PERCENT_MULT,
		data.speed_gain_over_life * age_fraction(),
		AGE_SPEED_SOURCE
	)
	stats.block.add_modifier(_age_modifier)


func _contact_damage(delta: float) -> void:
	for id: int in _contact_cooldowns.keys():
		_contact_cooldowns[id] -= delta
		if _contact_cooldowns[id] <= 0.0:
			_contact_cooldowns.erase(id)
	if data.contact_damage <= 0.0:
		return
	var reach: float = body_radius + CONTACT_MARGIN
	for target: Targetable in AttackUtils.player_targets(get_tree()):
		var id: int = target.get_instance_id()
		if _contact_cooldowns.has(id) or target.flat_distance_to(global_position) > reach:
			continue
		_contact_cooldowns[id] = data.contact_cooldown
		AttackUtils.damage(target, scaled_damage(data.contact_damage), data.damage_type, self)
