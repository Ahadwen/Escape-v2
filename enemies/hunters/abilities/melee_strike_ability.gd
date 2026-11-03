class_name MeleeStrikeAbility
extends HunterAbility
## A telegraphed melee strike: a cone in front, or a circle around the hunter.
## Direction locks when the wind-up starts. Can stun. Parryable.

enum Shape { CONE, CIRCLE }

## Extra reach so the strike connects with a body, not just its centre.
const BODY_MARGIN: float = 0.4

@export var shape: Shape = Shape.CONE
@export var radius: float = 2.2
@export var angle_degrees: float = 100.0
@export var wind_up: float = 0.5
@export var recovery: float = 0.6
@export var damage: float = 30.0
## Stun on hit (seconds, 0 = none).
@export var stun: float = 0.0
## Aim a little ahead of a moving target (seconds).
@export var lead: float = 0.15


func create_action(brain: HunterBrain) -> HunterAction:
	return Action.new(brain, self)


class Action:
	extends HunterAction

	var ability: MeleeStrikeAbility
	var _timer: float = 0.0
	var _striking: bool = true
	var _direction: Vector3 = Vector3.FORWARD
	var _origin: Vector3

	func _init(p_brain: HunterBrain, p_ability: MeleeStrikeAbility) -> void:
		super(p_brain)
		ability = p_ability

	func start() -> void:
		enemy().movement.stop()
		_direction = brain.direction_to_predicted(ability.lead)
		if _direction == Vector3.ZERO:
			_direction = enemy().movement.get_facing()
		enemy().movement.face_towards(_direction)
		_origin = enemy().global_position
		var reach: float = ability.radius + MeleeStrikeAbility.BODY_MARGIN
		if ability.shape == MeleeStrikeAbility.Shape.CIRCLE:
			brain.warning.show_circle(_origin, reach)
		else:
			brain.warning.show_cone(_origin, _direction, reach, ability.angle_degrees)
		_timer = ability.wind_up

	func tick(delta: float) -> bool:
		_timer -= delta
		if _striking:
			brain.warning.set_progress(1.0 - _timer / ability.wind_up)
			if _timer <= 0.0:
				_strike()
				_striking = false
				_timer = ability.recovery
			return false
		return _timer <= 0.0

	func cancel() -> void:
		brain.warning.clear()

	func _strike() -> void:
		brain.warning.clear()
		var reach: float = ability.radius + MeleeStrikeAbility.BODY_MARGIN
		var amount: float = enemy().scaled_damage(ability.damage)
		for target: Targetable in AttackUtils.player_targets(enemy().get_tree()):
			var at: Vector3 = target.world_position()
			var hit: bool
			if ability.shape == MeleeStrikeAbility.Shape.CIRCLE:
				hit = target.flat_distance_to(_origin) <= reach
			else:
				hit = AttackUtils.in_cone(_origin, _direction, reach, ability.angle_degrees, at)
			if not hit:
				continue
			AttackUtils.damage(target, amount, enemy().data.damage_type, enemy())
			if ability.stun > 0.0:
				AttackUtils.apply_status(target, StunEffect.new(ability.stun, &"hunter_stun"))
