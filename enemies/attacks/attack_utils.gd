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


static func player_targets(tree: SceneTree) -> Array[Targetable]:
	var targets: Array[Targetable] = []
	for node: Node in tree.get_nodes_in_group(Targetable.GROUP):
		var candidate: Targetable = node as Targetable
		if candidate != null and candidate.faction == Targetable.Faction.PLAYER:
			if candidate.is_targetable():
				targets.append(candidate)
	return targets


static func damage(
	target: Targetable, amount: float, type: DamageEvent.DamageType, source: Node
) -> void:
	if target.health != null:
		target.health.take_damage(DamageEvent.new(amount, type, source))


## Damages every player-faction target within radius of center. Returns hits.
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
			damage(target, amount, type, source)
			hits += 1
	return hits


## Damages every player-faction target within half_width of the segment a-b.
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
			damage(target, amount, type, source)
			hits += 1
	return hits
