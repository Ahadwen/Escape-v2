class_name ParryExecution
extends AbilityExecution
## Window -> (hit during window) success: knockback + stun around the caster,
## speed boost for a while -> end. A missed parry ends when the window closes.

signal parried

const PARRY_ID: StringName = &"parry"
const GRACE_ID: StringName = &"parry_grace"
const WINDOW_COLOR: Color = Color(0.6, 0.85, 1.0, 0.7)
const SUCCESS_COLOR: Color = Color(1.0, 1.0, 1.0, 0.9)

var _data: ParryAbilityData
var _window_left: float = 0.0
var _boost_left: float = 0.0
var _succeeded: bool = false
var _modifier: StatModifier
var _hold: HoldMovement


func _init(p_context: CastContext, data: ParryAbilityData) -> void:
	super(p_context)
	_data = data


func start() -> void:
	if context.status == null or context.health == null:
		finished = true
		return
	_window_left = _data.window
	context.status.apply(InvulnerableEffect.new(_data.window, PARRY_ID))
	context.health.damage_negated.connect(_on_damage_negated)
	# Rooted while parrying.
	if context.movement != null:
		_hold = HoldMovement.new(_data.window)
		context.movement.start_override(_hold, true)
	FxRing.spawn(
		context.caster.get_parent(), context.origin(), WINDOW_COLOR, 0.9, 1.3, _data.window
	)


func physics_tick(delta: float) -> void:
	if _succeeded:
		_boost_left -= delta
		if _boost_left <= 0.0:
			_end()
		return
	_window_left -= delta
	if _window_left <= 0.0:
		_end()


func cancel() -> void:
	_end()


func _on_damage_negated(event: DamageEvent) -> void:
	# Only direct hits while the parry itself is up count: not other
	# invulnerability, and not beams or ground effects (blocked, but no payoff).
	if _succeeded or not event.parryable or not context.status.has_effect(PARRY_ID):
		return
	_succeeded = true
	_release_hold()
	context.status.remove(PARRY_ID)
	context.status.apply(InvulnerableEffect.new(_data.success_grace, GRACE_ID))
	var center: Vector3 = context.origin()
	var stun: float = _data.stun_duration
	AreaEffects.knock_back(
		context.caster.get_tree(),
		center,
		_data.knockback_radius,
		_data.knockback_distance,
		func() -> StatusEffect: return StunEffect.new(stun, &"parry_stun")
	)
	AreaEffects.destroy_projectiles(context.caster.get_tree(), center, _data.knockback_radius)
	FxRing.spawn(
		context.caster.get_parent(), center, SUCCESS_COLOR, 0.8, _data.knockback_radius, 0.3
	)
	if context.stats != null:
		var amount: float = (
			_data.speed_scaling.evaluate(context.stats) if _data.speed_scaling != null else 0.8
		)
		_modifier = StatModifier.new(
			StatIds.MOVE_SPEED, StatModifier.Type.PERCENT_ADD, amount, &"ability:parry"
		)
		context.stats.add_modifier(_modifier)
	_boost_left = _data.speed_duration
	parried.emit()


func _release_hold() -> void:
	if _hold != null:
		_hold.cancel()
		_hold = null


func _end() -> void:
	if finished:
		return
	_release_hold()
	if context.health != null and context.health.damage_negated.is_connected(_on_damage_negated):
		context.health.damage_negated.disconnect(_on_damage_negated)
	if context.status != null:
		context.status.remove(PARRY_ID)
	if _modifier != null and context.stats != null:
		context.stats.remove_modifier(_modifier)
		_modifier = null
	finished = true
