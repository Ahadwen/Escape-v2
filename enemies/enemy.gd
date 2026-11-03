class_name Enemy
extends CharacterBody3D
## An enemy. Can't be killed: it exists for a limited lifetime, flickers as a
## warning, then despawns. Behaviour comes from the brain its EnemyData creates.

signal despawned(enemy: Enemy)

const GROUP: StringName = &"enemies"
## Speed of knockbacks applied to enemies, metres per second.
const KNOCKBACK_SPEED: float = 14.0

@export var data: EnemyData

var brain: EnemyBrain
var lifetime_remaining: float = 0.0

var _despawning: bool = false

@onready var stats: StatsComponent = $StatsComponent
@onready var movement: ActorMovement = $ActorMovement
@onready var status: StatusEffectHost = $StatusEffectHost
@onready var visual: Node3D = $Visual
@onready var body_mesh: MeshInstance3D = $Visual/Body


func _ready() -> void:
	add_to_group(GROUP)
	if data == null:
		push_error("Enemy spawned without EnemyData.")
		queue_free()
		return
	stats.initialize(data.get_base_stats())
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = data.color
	body_mesh.material_override = material
	lifetime_remaining = randf_range(data.lifetime_min, data.lifetime_max)
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
	if status.is_stunned():
		movement.stop()
	else:
		brain.tick(delta)


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


## Pushes the enemy away along a direction. Interrupts what it was doing.
func apply_knockback(direction: Vector3, distance: float) -> void:
	movement.start_override(DashMovement.new(direction, distance, KNOCKBACK_SPEED))
	if brain != null:
		brain.interrupt()


func apply_status(effect: StatusEffect) -> void:
	status.apply(effect)
	if effect.stuns and brain != null:
		brain.interrupt()
