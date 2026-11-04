class_name SkillshotAbility
extends HunterAbility
## An aimed shot with a line warning: tracks you, locks just before firing,
## then a projectile flies until it hits you, a wall or its range. Can slow
## or root what it hits, and scatter traps where it lands (Trapper's snipe,
## Broodmother's web).

enum OnHit { NONE, SLOW, ROOT }

@export var wind_up: float = 0.6
@export var lock_time: float = 0.2
@export var reach: float = 25.0
@export var warning_width: float = 0.5
@export var speed: float = 60.0
@export var radius: float = 0.3
@export var damage: float = 30.0
@export var color: Color = Color(1.0, 0.6, 0.2)
@export var on_hit: OnHit = OnHit.NONE
## SLOW: fraction of speed taken away.
@export var slow_amount: float = 0.4
@export var status_duration: float = 1.5
## Traps scattered around wherever the shot lands. 0 = none.
@export var trap_count: int = 0
@export var trap_spread: float = 2.2
@export var trap_root_time: float = 1.0
@export var trap_lifetime: float = 8.0
@export var trap_damage: float = 10.0
@export var recovery: float = 0.3


func create_action(brain: HunterBrain) -> HunterAction:
	return Action.new(brain, self)


class Action:
	extends HunterAction

	enum Phase { AIM, FLYING, RECOVER }

	var ability: SkillshotAbility
	var _phase: Phase = Phase.AIM
	var _timer: float = 0.0
	var _direction: Vector3 = Vector3.FORWARD
	var _shot: Projectile

	func _init(p_brain: HunterBrain, p_ability: SkillshotAbility) -> void:
		super(p_brain)
		ability = p_ability

	func start() -> void:
		enemy().movement.stop()
		_timer = ability.wind_up
		_aim()

	func _aim() -> void:
		_direction = lead_direction(ability.speed, maxf(_timer, 0.0))
		enemy().movement.face_towards(_direction)
		brain.warning.show_line(
			enemy().global_position, _direction, ability.reach, ability.warning_width
		)

	func tick(delta: float) -> bool:
		match _phase:
			Phase.AIM:
				_timer -= delta
				if _timer > ability.lock_time:
					_aim()
				brain.warning.set_progress(1.0 - _timer / ability.wind_up)
				if _timer <= 0.0:
					brain.warning.clear()
					_fire()
					_phase = Phase.RECOVER
					_timer = ability.recovery
			Phase.RECOVER:
				_timer -= delta
				return _timer <= 0.0
		return false

	func cancel() -> void:
		brain.warning.clear()

	func _fire() -> void:
		_shot = fire_shot(
			_direction, ability.speed, ability.damage, ability.radius, ability.color, ability.reach
		)
		# The shot outlives this action (and maybe the hunter): bind data, not self.
		_shot.impacted.connect(
			SkillshotAbility.on_impact.bind(
				ability, _shot.get_parent(), enemy().get_world_3d().navigation_map, weakref(enemy())
			)
		)


## Applies the on-hit status and scatters traps where a shot landed.
static func on_impact(
	point: Vector3,
	target: Targetable,
	ability: SkillshotAbility,
	world: Node,
	map: RID,
	source: WeakRef
) -> void:
	if target != null:
		match ability.on_hit:
			OnHit.SLOW:
				AttackUtils.apply_status(
					target, SlowEffect.new(ability.slow_amount, ability.status_duration, &"webbed")
				)
			OnHit.ROOT:
				AttackUtils.apply_status(target, RootEffect.new(ability.status_duration, &"pinned"))
	if ability.trap_count <= 0 or not is_instance_valid(world):
		return
	var turn: float = randf() * TAU
	for i: int in ability.trap_count:
		var angle: float = turn + TAU * i / ability.trap_count
		var offset: Vector3 = Vector3(cos(angle), 0.0, sin(angle)) * ability.trap_spread
		var trap: HunterTrap = HunterTrap.new()
		trap.root_time = ability.trap_root_time
		trap.lifetime = ability.trap_lifetime
		trap.damage_amount = ability.trap_damage
		trap.source = source.get_ref() as Node
		trap.position = NavigationServer3D.map_get_closest_point(map, point + offset)
		world.add_child(trap)
