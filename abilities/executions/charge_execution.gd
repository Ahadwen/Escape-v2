class_name ChargeExecution
extends AbilityExecution
## Invulnerable while charging. Hitting a wall or an enemy ends the charge
## and knocks nearby enemies back, briefly stunning them.

const INVULNERABLE_ID: StringName = &"charge_invulnerable"

var _data: ChargeAbilityData
var _movement: ChargeMovement


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
	context.movement.start_override(_movement)


func on_aim_updated() -> void:
	if _movement != null:
		_movement.steer_direction = context.aim.direction


func cancel() -> void:
	if _movement != null:
		_movement.cancel()


func _on_impacted(position: Vector3) -> void:
	var stun: float = _data.impact_stun
	AreaEffects.knock_back(
		context.caster.get_tree(),
		position,
		_data.impact_radius,
		_data.impact_knockback,
		func() -> StatusEffect: return StunEffect.new(stun, &"charge_impact")
	)


func _on_movement_ended() -> void:
	if context.status != null:
		context.status.remove(INVULNERABLE_ID)
	finished = true
