class_name RushAbility
extends HunterAbility
## The Brute's charge. No warning: it just goes, steering after you with a
## poor turning circle and speeding up the whole time. It only stops once it
## is past you along its own heading (a sidestep makes it overrun you), it
## hits you, or it runs out of steam. It smashes through terrain, so ducking
## behind a wall doesn't save you.

## Speed it starts from, as a multiple of its current move speed.
@export var start_speed_ratio: float = 1.0
@export var max_speed: float = 30.0
## Metres per second gained each second while charging.
@export var acceleration: float = 8.0
## How fast it comes to a halt once the charge ends.
@export var deceleration: float = 45.0
## Turn rate in degrees per second (low = wide turning circle).
@export var turn_rate_degrees: float = 60.0
## The charge ends once it is this far past you along its heading.
@export var pass_distance: float = 2.5
## Longest a charge can last.
@export var max_duration: float = 5.0
@export var width: float = 2.0
@export var damage: float = 100.0
@export var stun: float = 0.8
@export var knockback: float = 4.0
@export var recovery: float = 0.6
## How far ahead of you it steers (seconds of your movement).
@export var lead: float = 0.2


func create_action(brain: HunterBrain) -> HunterAction:
	return Action.new(brain, self)


class Action:
	extends HunterAction

	enum Phase { CHARGING, RECOVER }

	var ability: RushAbility
	var _phase: Phase = Phase.CHARGING
	var _timer: float = 0.0
	var _movement: MomentumMovement
	var _hit: Array[Targetable] = []

	func _init(p_brain: HunterBrain, p_ability: RushAbility) -> void:
		super(p_brain)
		ability = p_ability

	func start() -> void:
		var direction: Vector3 = brain.direction_to_predicted(ability.lead)
		if direction == Vector3.ZERO:
			direction = enemy().movement.get_facing()
		_movement = MomentumMovement.new(
			direction,
			enemy().movement.current_speed() * ability.start_speed_ratio,
			ability.max_speed,
			ability.acceleration,
			ability.deceleration,
			deg_to_rad(ability.turn_rate_degrees),
			ability.max_duration
		)
		_movement.wall_mode = MomentumMovement.WallMode.SMASH
		_movement.hit_obstacle.connect(Obstacles.destroy)
		enemy().movement.start_override(_movement)

	func tick(delta: float) -> bool:
		match _phase:
			Phase.CHARGING:
				if _movement.is_driving():
					_movement.steer_direction = brain.direction_to_predicted(ability.lead)
					_check_hits()
					if not _hit.is_empty() or _is_past_target():
						_movement.stop_driving()
				if _movement.finished:
					_phase = Phase.RECOVER
					_timer = ability.recovery
			Phase.RECOVER:
				_timer -= delta
				return _timer <= 0.0
		return false

	func cancel() -> void:
		if _movement != null:
			_movement.cancel()

	## True once the target is behind it by pass_distance along its heading.
	func _is_past_target() -> bool:
		if brain.target == null:
			return true
		var offset: Vector3 = brain.target.world_position() - enemy().global_position
		offset.y = 0.0
		return offset.dot(_movement.direction) < -ability.pass_distance

	func _check_hits() -> void:
		var from: Vector3 = enemy().global_position
		var reach: float = ability.width * 0.5 + enemy().body_radius
		for target: Targetable in AttackUtils.player_targets(enemy().get_tree()):
			if target in _hit or target.flat_distance_to(from) > reach:
				continue
			if AttackUtils.is_phased(target):
				continue
			_hit.append(target)
			AttackUtils.damage(
				target, enemy().scaled_damage(ability.damage), enemy().data.damage_type, enemy()
			)
			AttackUtils.apply_status(target, StunEffect.new(ability.stun, &"hunter_stun"))
			AttackUtils.displace(target, _movement.direction, ability.knockback, 18.0)
