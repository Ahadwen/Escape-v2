class_name ChargeExecution
extends AbilityExecution
## Invulnerable while charging, and passes through enemies, shoving each one
## aside (once per charge). Hitting a wall ends the charge and knocks nearby
## enemies back, briefly stunning them.

const INVULNERABLE_ID: StringName = &"charge_invulnerable"
## Physics layer 3 ("enemies").
const ENEMY_LAYER_BIT: int = 4
## How much of a shove goes forward along the charge vs sideways.
const PLOUGH_FORWARD_SHARE: float = 0.35

var _data: ChargeAbilityData
var _movement: ChargeMovement
var _body: CharacterBody3D
var _saved_mask: int = 0
var _ploughed: Array[Enemy] = []


func _init(p_context: CastContext, data: ChargeAbilityData) -> void:
	super(p_context)
	_data = data


func start() -> void:
	_movement = ChargeMovement.new(
		context.aim_direction(),
		_data.start_speed,
		_data.max_speed,
		_data.acceleration,
		deg_to_rad(_data.turn_rate_degrees),
		_data.max_duration
	)
	_movement.ended.connect(_on_movement_ended)
	_movement.impacted.connect(_on_impacted)
	if context.status != null:
		context.status.apply(InvulnerableEffect.new(_data.max_duration + 0.5, INVULNERABLE_ID))
	_body = context.caster as CharacterBody3D
	if _body != null:
		_saved_mask = _body.collision_mask
		_body.collision_mask = _saved_mask & ~ENEMY_LAYER_BIT
	context.movement.start_override(_movement)


func physics_tick(_delta: float) -> void:
	if _movement == null or _movement.finished:
		return
	var center: Vector3 = context.origin()
	for enemy: Enemy in AreaEffects.enemies_in_radius(
		context.caster.get_tree(), center, _data.plough_radius
	):
		if enemy in _ploughed:
			continue
		_ploughed.append(enemy)
		enemy.apply_knockback(
			plough_direction(_movement.direction, center, enemy.global_position),
			_data.plough_knockback
		)
		var stun: float = _data.plough_stun * AbilityData.duration_scale(context.stats)
		enemy.apply_status(StunEffect.new(stun, &"charge_plough"))


## Shove direction for an enemy at `point` hit by a charge moving along
## `charge_direction` from `center`: mostly to whichever side it's on, a bit
## forward.
static func plough_direction(charge_direction: Vector3, center: Vector3, point: Vector3) -> Vector3:
	var forward: Vector3 = Vector3(charge_direction.x, 0.0, charge_direction.z).normalized()
	var side: Vector3 = forward.cross(Vector3.UP)
	var offset: Vector3 = Vector3(point.x - center.x, 0.0, point.z - center.z)
	var side_sign: float = 1.0 if offset.dot(side) >= 0.0 else -1.0
	var push: Vector3 = (
		side * side_sign * (1.0 - PLOUGH_FORWARD_SHARE) + forward * PLOUGH_FORWARD_SHARE
	)
	return push.normalized()


func on_aim_updated() -> void:
	if _movement != null:
		_movement.steer_direction = context.aim.direction


func cancel() -> void:
	if _movement != null:
		_movement.cancel()


func _on_impacted(position: Vector3) -> void:
	var stun: float = _data.impact_stun * AbilityData.duration_scale(context.stats)
	AreaEffects.knock_back(
		context.caster.get_tree(),
		position,
		_data.impact_radius,
		_data.impact_knockback,
		func() -> StatusEffect: return StunEffect.new(stun, &"charge_impact")
	)


func _on_movement_ended() -> void:
	if _body != null:
		_body.collision_mask = _saved_mask
	if context.status != null:
		context.status.remove(INVULNERABLE_ID)
	finished = true
