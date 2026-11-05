class_name AttackUtils
extends RefCounted
## Shared helpers for enemy attacks: walls, line of sight, and damaging
## player-faction targets (the player and decoys) by shape.

const WORLD_MASK: int = 1
## Rays are cast at roughly chest height so low clutter doesn't block them.
const EYE_HEIGHT: float = 1.0


## Where a ray from -> to first hits a wall, or `to` if nothing is in the way.
## Call from physics processing.
static func ray_to_wall(world: World3D, from: Vector3, to: Vector3) -> Vector3:
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		from, to, WORLD_MASK
	)
	var hit: Dictionary = world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return to
	var position: Vector3 = hit["position"]
	return position


static func has_line_of_sight(world: World3D, from: Vector3, to: Vector3) -> bool:
	var raised_from: Vector3 = Vector3(from.x, from.y + EYE_HEIGHT, from.z)
	var raised_to: Vector3 = Vector3(to.x, to.y + EYE_HEIGHT, to.z)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		raised_from, raised_to, WORLD_MASK
	)
	return world.direct_space_state.intersect_ray(query).is_empty()


## Flat (XZ) distance from point p to the segment a-b.
static func point_segment_distance_flat(p: Vector3, a: Vector3, b: Vector3) -> float:
	var p2: Vector2 = Vector2(p.x, p.z)
	var a2: Vector2 = Vector2(a.x, a.z)
	var b2: Vector2 = Vector2(b.x, b.z)
	var ab: Vector2 = b2 - a2
	var length_squared: float = ab.length_squared()
	if length_squared < 0.000001:
		return p2.distance_to(a2)
	var t: float = clampf((p2 - a2).dot(ab) / length_squared, 0.0, 1.0)
	return p2.distance_to(a2 + ab * t)


## Phased targets (Q♠ Phase) are passed through by projectiles.
static func is_phased(target: Targetable) -> bool:
	var host: StatusEffectHost = (
		target.body.get_node_or_null("StatusEffectHost") as StatusEffectHost
	)
	return host != null and host.is_phased()


static func player_targets(tree: SceneTree) -> Array[Targetable]:
	var targets: Array[Targetable] = []
	for node: Node in tree.get_nodes_in_group(Targetable.GROUP):
		var candidate: Targetable = node as Targetable
		if candidate != null and candidate.faction == Targetable.Faction.PLAYER:
			if candidate.is_targetable():
				targets.append(candidate)
	return targets


static func damage(
	target: Targetable,
	amount: float,
	type: DamageEvent.DamageType,
	source: Node,
	parryable: bool = true
) -> void:
	if target.health != null:
		var event: DamageEvent = DamageEvent.new(amount, type, source)
		event.parryable = parryable
		target.health.take_damage(event)


## Applies a status (stun, root, slow) to a target unless it's invulnerable.
static func apply_status(target: Targetable, effect: StatusEffect) -> bool:
	var host: StatusEffectHost = _host(target)
	if host == null or host.is_invulnerable():
		return false
	host.apply(effect)
	return true


## Moves a target along a direction (pull or push) unless it's invulnerable.
static func displace(target: Targetable, direction: Vector3, distance: float, speed: float) -> bool:
	var host: StatusEffectHost = _host(target)
	if host != null and host.is_invulnerable():
		return false
	var movement: ActorMovement = target.body.get_node_or_null("ActorMovement") as ActorMovement
	if movement == null or distance <= 0.05:
		return false
	movement.start_override(DashMovement.new(direction, distance, speed))
	return true


static func _host(target: Targetable) -> StatusEffectHost:
	return target.body.get_node_or_null("StatusEffectHost") as StatusEffectHost


## True if `point` is in a cone (flat) of `radius` and `angle_degrees` total.
static func in_cone(
	origin: Vector3, direction: Vector3, radius: float, angle_degrees: float, point: Vector3
) -> bool:
	var offset: Vector2 = Vector2(point.x - origin.x, point.z - origin.z)
	if offset.length() > radius:
		return false
	if offset.length() < 0.5:
		return true
	var facing: Vector2 = Vector2(direction.x, direction.z)
	return absf(rad_to_deg(facing.angle_to(offset))) <= angle_degrees * 0.5


## Damages every player-faction target within radius of center. Returns hits.
## Area damage (barrages, ground zones) can't be parried.
static func damage_in_radius(
	tree: SceneTree,
	center: Vector3,
	radius: float,
	amount: float,
	type: DamageEvent.DamageType,
	source: Node
) -> int:
	var hits: int = 0
	for target: Targetable in player_targets(tree):
		if target.flat_distance_to(center) <= radius:
			damage(target, amount, type, source, false)
			hits += 1
	return hits


## Damages every player-faction target within half_width of the segment a-b.
## Beam damage can't be parried.
static func damage_on_segment(
	tree: SceneTree,
	a: Vector3,
	b: Vector3,
	half_width: float,
	amount: float,
	type: DamageEvent.DamageType,
	source: Node
) -> int:
	var hits: int = 0
	for target: Targetable in player_targets(tree):
		if point_segment_distance_flat(target.world_position(), a, b) <= half_width:
			damage(target, amount, type, source, false)
			hits += 1
	return hits
