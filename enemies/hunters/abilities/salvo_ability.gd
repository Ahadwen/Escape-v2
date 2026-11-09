class_name SalvoAbility
extends HunterAbility
## The Gunslinger's salvo: he holds the trigger and sweeps his aim left and
## right across you (a steady zigzag around the line to you), spraying a fan of
## straight shots you have to slip between, then a heavy straight shot with
## its own tell (body flash + aim line), then a reload: a visible gap in the
## shooting that's your window. He keeps moving throughout.

@export var shots: int = 5
@export var interval: float = 0.32
@export var shot_speed: float = 34.0
@export var shot_radius: float = 0.25
@export var shot_damage: float = 22.0
@export var reach: float = 22.0
## The spray sweeps this many degrees either side of the line to you ...
@export var sweep_degrees: float = 0.0
## ... this many full left-right-left sweeps a second.
@export var sweep_frequency: float = 1.5
## How much of your movement the light shots lead (1 = full). Under 1 they
## pressure rather than snipe; the final shot always leads fully.
@export_range(0.0, 1.0) var light_lead_ratio: float = 0.7
@export var final_tell: float = 0.45
@export var final_lock: float = 0.15
@export var final_speed: float = 50.0
@export var final_radius: float = 0.55
@export var final_damage: float = 60.0
@export var reload: float = 1.6
@export var color: Color = Color(1.0, 0.85, 0.35)


## A steady left-right sweep: -1..1 and back once per unit of `cycles`,
## starting at the centre and moving at a constant rate.
static func zigzag(cycles: float) -> float:
	var t: float = fposmod(cycles + 0.25, 1.0)
	return 4.0 * absf(t - 0.5) - 1.0


func create_action(brain: HunterBrain) -> HunterAction:
	return Action.new(brain, self)


class Action:
	extends HunterAction

	enum Phase { SHOOTING, FINAL_TELL, RELOAD }

	var ability: SalvoAbility
	var _phase: Phase = Phase.SHOOTING
	var _timer: float = 0.0
	var _fired: int = 0
	var _direction: Vector3 = Vector3.FORWARD

	func _init(p_brain: HunterBrain, p_ability: SalvoAbility) -> void:
		super(p_brain)
		ability = p_ability

	func start() -> void:
		_timer = 0.05

	func tick(delta: float) -> bool:
		match _phase:
			Phase.SHOOTING:
				brain.pursue(delta)
				_timer -= delta
				if _timer <= 0.0:
					_light_shot()
			Phase.FINAL_TELL:
				brain.pursue(delta)
				_timer -= delta
				if _timer > ability.final_lock:
					_aim_final()
				else:
					# Direction is locked; the line follows him as he moves.
					brain.warning.show_line(
						enemy().global_position,
						_direction,
						ability.reach,
						ability.final_radius * 2.0
					)
				brain.warning.set_progress(1.0 - _timer / ability.final_tell)
				if _timer <= 0.0:
					_final_shot()
			Phase.RELOAD:
				brain.pursue(delta)
				_timer -= delta
				return _timer <= 0.0
		return false

	func cancel() -> void:
		brain.warning.clear()
		enemy().set_tell(false)

	func _light_shot() -> void:
		var flight: float = brain.distance_to_target() / ability.shot_speed
		var direction: Vector3 = brain.direction_to_predicted(flight * ability.light_lead_ratio)
		if direction == Vector3.ZERO:
			direction = enemy().movement.get_facing()
		# The spray: swing the aim side to side around the line to you at a
		# steady rate (a zigzag, not a sine, which would linger at the edges
		# and send most shots wide).
		var sweep: float = SalvoAbility.zigzag(ability.sweep_frequency * _fired * ability.interval)
		direction = direction.rotated(Vector3.UP, deg_to_rad(ability.sweep_degrees) * sweep)
		fire_shot(
			direction,
			ability.shot_speed,
			ability.shot_damage,
			ability.shot_radius,
			ability.color,
			ability.reach
		)
		_fired += 1
		_timer = ability.interval
		if _fired >= ability.shots - 1:
			enemy().set_tell(true)
			_phase = Phase.FINAL_TELL
			_timer = ability.final_tell
			_aim_final()

	func _aim_final() -> void:
		_direction = lead_direction(ability.final_speed, maxf(_timer, 0.0))
		enemy().movement.face_towards(_direction)
		brain.warning.show_line(
			enemy().global_position, _direction, ability.reach, ability.final_radius * 2.0
		)

	func _final_shot() -> void:
		brain.warning.clear()
		enemy().set_tell(false)
		fire_shot(
			_direction,
			ability.final_speed,
			ability.final_damage,
			ability.final_radius,
			ability.color.lightened(0.3),
			ability.reach
		)
		_phase = Phase.RELOAD
		_timer = ability.reload
