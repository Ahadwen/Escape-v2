class_name HunterAction
extends RefCounted
## A hunter ability in progress (wind-up, effect, recovery). While an action
## runs the hunter doesn't chase.

var brain: HunterBrain


func _init(p_brain: HunterBrain) -> void:
	brain = p_brain


func enemy() -> Enemy:
	return brain.enemy


func start() -> void:
	pass


## Returns true when finished.
func tick(_delta: float) -> bool:
	return true


## Interrupted (knockback, stun) or the hunter is leaving.
func cancel() -> void:
	pass


## Adds an attack node (shot, trap, blast) to the world beside the hunter.
func spawn_in_world(node: Node3D) -> void:
	enemy().get_parent().add_child(node)


## Fires a straight shot from the hunter. Returns it (connect `impacted`).
func fire_shot(
	direction: Vector3, speed: float, damage: float, radius: float, color: Color, reach: float
) -> Projectile:
	var shot: Projectile = Projectile.new()
	shot.configure(
		enemy().global_position,
		direction,
		speed,
		enemy().scaled_damage(damage),
		enemy().data.damage_type,
		enemy(),
		radius
	)
	shot.color = color
	shot.max_distance = reach
	spawn_in_world(shot)
	return shot


## Direction to lead a shot of `speed` (plus `extra` seconds) at the target.
func lead_direction(speed: float, extra: float = 0.0) -> Vector3:
	var flight: float = brain.distance_to_target() / maxf(speed, 0.1)
	var direction: Vector3 = brain.direction_to_predicted(flight + extra)
	return direction if direction != Vector3.ZERO else enemy().movement.get_facing()
