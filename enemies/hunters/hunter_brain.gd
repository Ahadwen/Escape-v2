class_name HunterBrain
extends EnemyBrain
## Generic hunter: pursue (intercepting, flanking) and use abilities from its
## kit when they're ready and usable. Applies the pursuit speed rule.

## Seconds between route recalculations (route_to_predicted).
const ROUTE_INTERVAL: float = 0.15
## Path corners closer than this are treated as already passed.
const ROUTE_CORNER_DISTANCE: float = 1.5
## Strafing hunters aim to be beside where you'll be this far ahead.
const STRAFE_LEAD: float = 0.6
## holds_ahead only kicks in once you've been heading somewhere this fast.
const HOLD_AHEAD_MIN_SPEED: float = 3.0

var hunter: HunterData
var current_action: HunterAction
## Ground warnings for this hunter's abilities.
var warning: Telegraph

var _cooldowns: Array[float] = []
var _route_timer: float = 0.0
var _route_direction: Vector3 = Vector3.ZERO
var _spin: float = 0.0
var _wobble_time: float = 0.0


func _init(p_data: HunterData) -> void:
	hunter = p_data
	for ability: HunterAbility in hunter.abilities:
		_cooldowns.append(ability.initial_cooldown)


func _ready() -> void:
	super()
	warning = Telegraph.new()
	add_child(warning)


func think(delta: float) -> void:
	_update_speed_floor()
	for i: int in _cooldowns.size():
		_cooldowns[i] -= delta
	if target != null and not is_instance_valid(target):
		target = null
	if current_action != null and target == null:
		# Target gone (died, or a decoy expired): abilities assume one.
		warning.clear()
		current_action.cancel()
		current_action = null
	if current_action != null:
		if _try_interrupting_ability():
			return
		if current_action.tick(delta):
			current_action = null
		return
	if target == null:
		wander(delta)
		return
	for i: int in hunter.abilities.size():
		if _try_ability(i):
			return
	pursue(delta)


## Melee hunters close in; ranged ones hold their band while they have a
## clear shot (running alongside if they strafe) and chase around walls to
## get one when they don't.
func pursue(delta: float) -> void:
	if hunter.preferred_range_max <= 0.0 or not has_line_of_sight_to_target():
		chase(delta)
	elif hunter.strafes or hunter.holds_ahead:
		_strafe(delta)
	else:
		keep_distance(delta, hunter.preferred_range_min, hunter.preferred_range_max)


func _try_ability(index: int) -> bool:
	var ability: HunterAbility = hunter.abilities[index]
	if _cooldowns[index] > 0.0 or not ability.can_use(self):
		return false
	_cooldowns[index] = ability.cooldown
	if current_action != null:
		warning.clear()
		current_action.cancel()
	current_action = ability.create_action(self)
	current_action.start()
	return true


func _try_interrupting_ability() -> bool:
	for i: int in hunter.abilities.size():
		if hunter.abilities[i].interrupts and _try_ability(i):
			return true
	return false


## Keeps pace beside the target: heads for a point at the middle of the band,
## on this hunter's side of where the target is going.
func _strafe(delta: float) -> void:
	_repath_timer -= delta
	if _repath_timer > 0.0:
		return
	_repath_timer = REPATH_INTERVAL
	var goal: Vector3 = target.predicted_position(STRAFE_LEAD)
	var side: Vector3 = enemy.global_position - goal
	side.y = 0.0
	if side.length_squared() < 0.01:
		side = Vector3.RIGHT
	var heading: Vector3 = target.average_velocity
	if hunter.holds_ahead and heading.length() > HOLD_AHEAD_MIN_SPEED:
		# Between its side and straight ahead of where you're going.
		side = side.normalized() + heading.normalized() * 1.5
	var band: float = (hunter.preferred_range_min + hunter.preferred_range_max) * 0.5
	enemy.movement.move_to(goal + side.normalized() * band)


func interrupt() -> void:
	super()
	warning.clear()
	if current_action != null:
		current_action.cancel()
		current_action = null


## Direction toward where the target will be after `lead` seconds, routed
## around walls: the way to the next corner of the navigation path, or
## straight at them when nothing is in the way. Recomputed a few times a
## second.
func route_to_predicted(lead: float) -> Vector3:
	_route_timer -= get_physics_process_delta_time()
	if _route_timer > 0.0 and _route_direction != Vector3.ZERO:
		return _route_direction
	_route_timer = ROUTE_INTERVAL
	_route_direction = direction_to_predicted(lead)
	if target == null or has_line_of_sight_to_target():
		return _route_direction
	var from: Vector3 = enemy.global_position
	var path: PackedVector3Array = NavigationServer3D.map_get_path(
		enemy.get_world_3d().navigation_map,
		from,
		target.predicted_position(lead),
		true,
		enemy.movement.navigation_layers
	)
	var index: int = ActorMovement.next_waypoint_index(path, 0, from, ROUTE_CORNER_DISTANCE)
	if index < path.size():
		var offset: Vector3 = Vector3(path[index].x - from.x, 0.0, path[index].z - from.z)
		if offset.length_squared() > 0.0001:
			_route_direction = offset.normalized()
	return _route_direction


## The player's sustained speed: base + permanent bonuses (cards), without
## temporary boosts or slows (status effects).
static func sustained_speed(player: Node) -> float:
	var stats: StatsComponent = player.get_node_or_null("StatsComponent") as StatsComponent
	if stats == null:
		return 0.0
	return stats.block.get_value_excluding(StatIds.MOVE_SPEED, "status:")


## Pursuit rule: never slower than the target's sustained speed x ratio, and
## sprinting when far away so distance buys time, not safety.
func _update_speed_floor() -> void:
	if target == null:
		enemy.movement.speed_floor = 0.0
		return
	var pursuit: float = maxf(
		enemy.data.move_speed, sustained_speed(target.body) * hunter.speed_floor_ratio
	)
	if distance_to_target() > hunter.catch_up_distance:
		pursuit *= hunter.catch_up_multiplier
	enemy.movement.speed_floor = pursuit


func _process(delta: float) -> void:
	if not hunter.spins or enemy == null or enemy.model == null:
		return
	var busy: bool = current_action != null and current_action is ZoomAbility.Action
	var zooming: bool = busy and (current_action as ZoomAbility.Action).is_zooming()
	_spin = wrapf(_spin + (24.0 if zooming else 9.0) * delta, -PI, PI)
	_wobble_time += delta
	var wobble: float = 0.0 if zooming else 0.22
	enemy.model.rotation = Vector3(
		sin(_wobble_time * 9.0) * wobble, _spin, cos(_wobble_time * 7.0) * wobble
	)
