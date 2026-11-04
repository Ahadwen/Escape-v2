class_name HunterBrain
extends EnemyBrain
## Generic hunter: pursue (intercepting, flanking) and use abilities from its
## kit when they're ready and usable. Applies the pursuit speed rule.

## Seconds between route recalculations (route_to_predicted).
const ROUTE_INTERVAL: float = 0.15
## Path corners closer than this are treated as already passed.
const ROUTE_CORNER_DISTANCE: float = 1.5

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
	if current_action != null:
		if current_action.tick(delta):
			current_action = null
		return
	if target == null:
		wander(delta)
		return
	for i: int in hunter.abilities.size():
		var ability: HunterAbility = hunter.abilities[i]
		if _cooldowns[i] <= 0.0 and ability.can_use(self):
			_cooldowns[i] = ability.cooldown
			current_action = ability.create_action(self)
			current_action.start()
			return
	_pursue(delta)


## Melee hunters close in; ranged ones hold their band while they have a
## clear shot and chase (around walls) to get one when they don't.
func _pursue(delta: float) -> void:
	if hunter.preferred_range_max > 0.0 and has_line_of_sight_to_target():
		keep_distance(delta, hunter.preferred_range_min, hunter.preferred_range_max)
	else:
		chase(delta)


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
