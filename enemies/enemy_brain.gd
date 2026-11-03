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
## Never predict further ahead than this when intercepting.
const MAX_LEAD_TIME: float = 1.2
## Beyond this distance, approach from the enemy's own flank angle.
const FLANK_START_DISTANCE: float = 6.0
const MAX_FLANK_ANGLE_DEGREES: float = 70.0
const MAX_FLANK_OFFSET: float = 6.0

var enemy: Enemy
var target: Targetable
## Ground indicator for telegraphs. Top-level so it doesn't move with the enemy.
var telegraph: AimIndicator

var _retarget_timer: float = 0.0
var _repath_timer: float = 0.0
var _wander_timer: float = 0.0
## Each enemy's preferred approach angle, so packs surround rather than queue.
var _flank_angle: float = 0.0


func setup(p_enemy: Enemy) -> void:
	enemy = p_enemy


func _ready() -> void:
	_flank_angle = deg_to_rad(randf_range(-MAX_FLANK_ANGLE_DEGREES, MAX_FLANK_ANGLE_DEGREES))
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
		enemy.movement.move_to(chase_point())


## Where to run to: ahead of the target (interception), offset to this
## enemy's flank while still far away so packs close in from several sides.
func chase_point() -> Vector3:
	var from: Vector3 = enemy.global_position
	var distance: float = distance_to_target()
	var speed: float = maxf(enemy.movement.current_speed(), 0.1)
	var lead: float = clampf(distance / speed, 0.0, MAX_LEAD_TIME)
	var predicted: Vector3 = target.predicted_position(lead)
	return flank_point(from, predicted, _flank_angle, distance)


## Pure helper: point near `goal`, rotated around it toward the enemy's flank
## angle. No offset once within FLANK_START_DISTANCE.
static func flank_point(
	from: Vector3, goal: Vector3, flank_angle: float, distance: float
) -> Vector3:
	if distance <= FLANK_START_DISTANCE:
		return goal
	var to_enemy: Vector3 = Vector3(from.x - goal.x, 0.0, from.z - goal.z)
	if to_enemy.length_squared() < 0.0001:
		return goal
	var side: Vector3 = to_enemy.normalized().rotated(Vector3.UP, flank_angle)
	var offset: float = minf((distance - FLANK_START_DISTANCE) * 0.5, MAX_FLANK_OFFSET)
	return goal + side * offset


## Direction toward where the target will be after `lead` seconds.
func direction_to_predicted(lead: float) -> Vector3:
	if target == null:
		return Vector3.ZERO
	var offset: Vector3 = target.predicted_position(lead) - enemy.global_position
	offset.y = 0.0
	return offset.normalized() if offset.length_squared() > 0.0001 else direction_to_target()


## Damages each PLAYER-faction target within radius not already in `already_hit`
## (which is updated). Used by dash/lunge attacks.
func hit_targets_in_radius(radius: float, already_hit: Array[Targetable]) -> void:
	var from: Vector3 = enemy.global_position
	for node: Node in enemy.get_tree().get_nodes_in_group(Targetable.GROUP):
		var candidate: Targetable = node as Targetable
		if candidate == null or candidate.faction != Targetable.Faction.PLAYER:
			continue
		if candidate in already_hit or not candidate.is_targetable():
			continue
		if candidate.flat_distance_to(from) <= radius:
			already_hit.append(candidate)
			deal_damage(candidate)


## Ranged behaviour: back off when closer than min_distance, close in when
## further than max_distance, hold position in between.
func keep_distance(delta: float, min_distance: float, max_distance: float) -> void:
	var distance: float = distance_to_target()
	if distance > max_distance:
		chase(delta)
		return
	if distance >= min_distance:
		enemy.movement.stop()
		_repath_timer = 0.0
		return
	_repath_timer -= delta
	if _repath_timer > 0.0:
		return
	_repath_timer = REPATH_INTERVAL
	var away: Vector3 = -direction_to_target()
	var retreat: Vector3 = enemy.global_position + away * (min_distance - distance + 2.0)
	enemy.movement.move_to(retreat)


func has_line_of_sight_to_target() -> bool:
	if target == null:
		return false
	return AttackUtils.has_line_of_sight(
		enemy.get_world_3d(), enemy.global_position, target.world_position()
	)


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
