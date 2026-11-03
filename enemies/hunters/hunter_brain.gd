class_name HunterBrain
extends EnemyBrain
## Generic hunter: pursue (intercepting, flanking) and use abilities from its
## kit when they're ready and usable. Applies the pursuit speed rule.

var hunter: HunterData
var current_action: HunterAction
## Ground warnings for this hunter's abilities.
var warning: Telegraph

var _cooldowns: Array[float] = []
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
	chase(delta)


func interrupt() -> void:
	super()
	warning.clear()
	if current_action != null:
		current_action.cancel()
		current_action = null


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
