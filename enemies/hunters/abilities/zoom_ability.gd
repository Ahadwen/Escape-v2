class_name ZoomAbility
extends HunterAbility
## The Spinner's core move: a short wobble to re-aim, then a zoom with real
## momentum: accelerate toward you, curve after you with a poor turning
## circle, then slow and coast to a stop. Contact damage is on the enemy.

@export var aim_time: float = 0.4
@export var start_speed: float = 6.0
@export var max_speed: float = 24.0
@export var acceleration: float = 30.0
@export var deceleration: float = 14.0
@export var turn_rate_degrees: float = 55.0
@export var drive_time: float = 1.6
@export var recovery: float = 0.6


func create_action(brain: HunterBrain) -> HunterAction:
	return Action.new(brain, self)


class Action:
	extends HunterAction

	enum Phase { AIM, ZOOM, WOBBLE }

	var ability: ZoomAbility
	var _phase: Phase = Phase.AIM
	var _timer: float = 0.0
	var _movement: MomentumMovement

	func _init(p_brain: HunterBrain, p_ability: ZoomAbility) -> void:
		super(p_brain)
		ability = p_ability

	func is_zooming() -> bool:
		return _phase == Phase.ZOOM

	func start() -> void:
		enemy().movement.stop()
		_timer = ability.aim_time

	func tick(delta: float) -> bool:
		match _phase:
			Phase.AIM:
				_timer -= delta
				if _timer <= 0.0:
					var direction: Vector3 = brain.direction_to_predicted(0.3)
					if direction == Vector3.ZERO:
						direction = enemy().movement.get_facing()
					_movement = MomentumMovement.new(
						direction,
						ability.start_speed,
						ability.max_speed,
						ability.acceleration,
						ability.deceleration,
						deg_to_rad(ability.turn_rate_degrees),
						ability.drive_time
					)
					enemy().movement.start_override(_movement)
					_phase = Phase.ZOOM
			Phase.ZOOM:
				_movement.steer_direction = brain.direction_to_predicted(0.4)
				if _movement.finished:
					_phase = Phase.WOBBLE
					_timer = ability.recovery
			Phase.WOBBLE:
				_timer -= delta
				return _timer <= 0.0
		return false

	func cancel() -> void:
		if _movement != null:
			_movement.cancel()
