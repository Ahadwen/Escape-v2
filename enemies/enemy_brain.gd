class_name EnemyBrain
extends Node
## Decides what an enemy does each physics frame. Shared helpers handle
## target selection, chasing, wandering and dealing damage; subclasses
## implement the archetype's state machine in think().

const RETARGET_INTERVAL: float = 0.25
const REPATH_INTERVAL: float = 0.3
const WANDER_RADIUS: float = 5.0
const WANDER_INTERVAL_MIN: float = 2.0
const WANDER_INTERVAL_MAX: float = 4.0
const TELEGRAPH_COLOR: Color = Color(1.0, 0.25, 0.2, 0.55)

var enemy: Enemy
var target: Targetable
## Ground indicator for telegraphs. Top-level so it doesn't move with the enemy.
var telegraph: AimIndicator

var _retarget_timer: float = 0.0
var _repath_timer: float = 0.0
var _wander_timer: float = 0.0


func setup(p_enemy: Enemy) -> void:
	enemy = p_enemy


func _ready() -> void:
	telegraph = AimIndicator.new()
	telegraph.color = TELEGRAPH_COLOR
	telegraph.top_level = true
	add_child(telegraph)


## Called by the enemy every physics frame while it isn't stunned.
func tick(delta: float) -> void:
	_update_target(delta)
	think(delta)


## Override: the archetype's behaviour.
func think(delta: float) -> void:
	if target == null:
		wander(delta)
	else:
		chase(delta)


## Called when something interrupts the enemy (knockback, stun).
func interrupt() -> void:
	telegraph.clear()


func data() -> EnemyData:
	return enemy.data


func distance_to_target() -> float:
	return target.flat_distance_to(enemy.global_position) if target != null else INF


func direction_to_target() -> Vector3:
	if target == null:
		return Vector3.ZERO
	var offset: Vector3 = target.world_position() - enemy.global_position
	offset.y = 0.0
	return offset.normalized() if offset.length_squared() > 0.0001 else Vector3.ZERO


func chase(delta: float) -> void:
	_repath_timer -= delta
	if _repath_timer <= 0.0:
		_repath_timer = REPATH_INTERVAL
		enemy.movement.move_to(target.world_position())


func wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer > 0.0:
		return
	_wander_timer = randf_range(WANDER_INTERVAL_MIN, WANDER_INTERVAL_MAX)
	var angle: float = randf() * TAU
	var offset: Vector3 = Vector3(cos(angle), 0.0, sin(angle)) * randf_range(1.0, WANDER_RADIUS)
	enemy.movement.move_to(enemy.global_position + offset)


func deal_damage(to: Targetable) -> void:
	if to != null and to.health != null:
		to.health.take_damage(DamageEvent.new(data().damage, data().damage_type, enemy))


func _update_target(delta: float) -> void:
	_retarget_timer -= delta
	if _retarget_timer > 0.0:
		return
	_retarget_timer = RETARGET_INTERVAL
	var from: Vector3 = enemy.global_position
	if target != null and not target.is_targetable():
		target = null
	var lose_range: float = data().lose_interest_range
	if target != null and lose_range > 0.0 and target.flat_distance_to(from) > lose_range:
		target = null
	# Something more interesting in sight (e.g. a decoy) takes over.
	var best: Targetable = Targetable.find_best(
		enemy.get_tree(), from, Targetable.Faction.PLAYER, data().sight_range
	)
	if best != null and (target == null or best.priority > target.priority):
		target = best
