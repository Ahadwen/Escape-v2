class_name Targetable
extends Node
## Something enemies can target. Enemies never reference "the player"
## directly: they pick the best Targetable, so decoys (higher priority) and
## other lures work without special cases.

enum Faction { PLAYER, ENEMY }

const GROUP: StringName = &"targetables"

@export var body: Node3D
@export var faction: Faction = Faction.PLAYER
## Higher priority wins over distance.
@export var priority: int = 0
## Optional. A dead target is no longer targetable.
@export var health: HealthComponent


## Picks the highest-priority, then nearest, candidate of a faction within
## max_range (flat distance) of from.
static func pick_best(
	candidates: Array[Targetable], from: Vector3, faction_filter: Faction, max_range: float
) -> Targetable:
	var best: Targetable = null
	var best_distance: float = INF
	for candidate: Targetable in candidates:
		if candidate.faction != faction_filter or not candidate.is_targetable():
			continue
		var distance: float = candidate.flat_distance_to(from)
		if distance > max_range:
			continue
		var better: bool = (
			best == null
			or candidate.priority > best.priority
			or (candidate.priority == best.priority and distance < best_distance)
		)
		if better:
			best = candidate
			best_distance = distance
	return best


static func find_best(
	tree: SceneTree, from: Vector3, faction_filter: Faction, max_range: float
) -> Targetable:
	var candidates: Array[Targetable] = []
	for node: Node in tree.get_nodes_in_group(GROUP):
		if node is Targetable:
			candidates.append(node as Targetable)
	return pick_best(candidates, from, faction_filter, max_range)


func _enter_tree() -> void:
	add_to_group(GROUP)


func is_targetable() -> bool:
	return is_inside_tree() and body != null and (health == null or not health.is_dead)


func world_position() -> Vector3:
	return body.global_position


func flat_distance_to(point: Vector3) -> float:
	var p: Vector3 = world_position()
	return Vector2(p.x - point.x, p.z - point.z).length()
