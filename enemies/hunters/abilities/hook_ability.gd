class_name HookAbility
extends HunterAbility
## The Harpooner's hook: a long, thin, telegraphed skillshot. If it catches a
## player-faction target, they're pulled to the Harpooner and briefly stunned.
## Walls stop it. Parryable (a parry blocks the pull).

@export var wind_up: float = 0.7
@export var range_m: float = 15.0
@export var width: float = 0.7
@export var projectile_speed: float = 30.0
@export var damage: float = 15.0
@export var pull_speed: float = 26.0
## Pulled targets stop this far from the Harpooner.
@export var pull_stop: float = 1.8
@export var stun_after_pull: float = 0.5
@export var recovery: float = 0.7
@export var lead: float = 0.2


func create_action(brain: HunterBrain) -> HunterAction:
	return Action.new(brain, self)


class Action:
	extends HunterAction

	enum Phase { WIND_UP, FLYING, RECOVER }

	var ability: HookAbility
	var _phase: Phase = Phase.WIND_UP
	var _timer: float = 0.0
	var _direction: Vector3
	var _travelled: float = 0.0
	var _hook: MeshInstance3D

	func _init(p_brain: HunterBrain, p_ability: HookAbility) -> void:
		super(p_brain)
		ability = p_ability

	func start() -> void:
		enemy().movement.stop()
		_direction = brain.direction_to_predicted(ability.lead)
		if _direction == Vector3.ZERO:
			_direction = enemy().movement.get_facing()
		enemy().movement.face_towards(_direction)
		brain.warning.show_line(enemy().global_position, _direction, ability.range_m, ability.width)
		_timer = ability.wind_up

	func tick(delta: float) -> bool:
		match _phase:
			Phase.WIND_UP:
				_timer -= delta
				brain.warning.set_progress(1.0 - _timer / ability.wind_up)
				if _timer <= 0.0:
					brain.warning.clear()
					_spawn_hook_visual()
					_phase = Phase.FLYING
			Phase.FLYING:
				if _fly(delta):
					_finish_flight()
			Phase.RECOVER:
				_timer -= delta
				return _timer <= 0.0
		return false

	func cancel() -> void:
		brain.warning.clear()
		_free_visual()

	## Moves the hook head. Returns true when it hits something or runs out.
	func _fly(delta: float) -> bool:
		var origin: Vector3 = enemy().global_position
		var before: float = _travelled
		_travelled = minf(_travelled + ability.projectile_speed * delta, ability.range_m)
		var from: Vector3 = origin + _direction * before
		var to: Vector3 = origin + _direction * _travelled
		var raised: Vector3 = Vector3.UP * AttackUtils.EYE_HEIGHT
		var stop: Vector3 = AttackUtils.ray_to_wall(
			enemy().get_world_3d(), from + raised, to + raised
		)
		var wall: bool = not stop.is_equal_approx(to + raised)
		if is_instance_valid(_hook):
			_hook.global_position = stop
		for target: Targetable in AttackUtils.player_targets(enemy().get_tree()):
			var near: float = AttackUtils.point_segment_distance_flat(
				target.world_position(), from, to
			)
			if near <= ability.width * 0.5 + 0.4:
				_catch(target)
				return true
		return wall or _travelled >= ability.range_m

	func _catch(target: Targetable) -> void:
		AttackUtils.damage(
			target, enemy().scaled_damage(ability.damage), enemy().data.damage_type, enemy()
		)
		# Invulnerable targets (a parry, the charge) aren't pulled: displace()
		# refuses them.
		var to_hunter: Vector3 = enemy().global_position - target.world_position()
		var distance: float = Vector2(to_hunter.x, to_hunter.z).length() - ability.pull_stop
		if AttackUtils.displace(target, to_hunter, distance, ability.pull_speed):
			var stun: float = distance / ability.pull_speed + ability.stun_after_pull
			AttackUtils.apply_status(target, StunEffect.new(stun, &"hooked"))

	func _finish_flight() -> void:
		_free_visual()
		_phase = Phase.RECOVER
		_timer = ability.recovery

	func _spawn_hook_visual() -> void:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.8, 0.8, 0.85)
		material.emission_enabled = true
		material.emission = Color(0.6, 0.6, 0.7)
		var head: BoxMesh = BoxMesh.new()
		head.size = Vector3(0.5, 0.3, 0.7)
		head.material = material
		_hook = MeshInstance3D.new()
		_hook.mesh = head
		_hook.top_level = true
		brain.add_child(_hook)
		_hook.global_position = enemy().global_position + Vector3.UP * AttackUtils.EYE_HEIGHT

	func _free_visual() -> void:
		if is_instance_valid(_hook):
			_hook.queue_free()
