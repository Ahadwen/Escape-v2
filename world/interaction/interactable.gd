class_name Interactable
extends Node
## Something the player can interact with (chests, later shops and doors).
## Interact with F / A / the touch Interact button when in range, or
## right-click it on PC to walk over and interact on arrival.

signal interacted(player: Player)

const GROUP: StringName = &"interactables"

@export var target: Node3D
@export var interact_range: float = 2.2
@export var prompt: String = "Interact"
var enabled: bool = true


## The closest enabled interactable whose range includes `from`, or null.
static func nearest_in_range(tree: SceneTree, from: Vector3) -> Interactable:
	var best: Interactable = null
	var best_distance: float = INF
	for node: Node in tree.get_nodes_in_group(GROUP):
		var candidate: Interactable = node as Interactable
		if candidate == null or not candidate.enabled or candidate.target == null:
			continue
		var distance: float = candidate.flat_distance_to(from)
		if distance <= candidate.interact_range and distance < best_distance:
			best = candidate
			best_distance = distance
	return best


## The closest enabled interactable within `radius` of a clicked point.
static func nearest_to_point(tree: SceneTree, point: Vector3, radius: float) -> Interactable:
	var best: Interactable = null
	var best_distance: float = radius
	for node: Node in tree.get_nodes_in_group(GROUP):
		var candidate: Interactable = node as Interactable
		if candidate == null or not candidate.enabled or candidate.target == null:
			continue
		var distance: float = candidate.flat_distance_to(point)
		if distance <= best_distance:
			best = candidate
			best_distance = distance
	return best


func _enter_tree() -> void:
	add_to_group(GROUP)


func world_position() -> Vector3:
	return target.global_position


func flat_distance_to(point: Vector3) -> float:
	var p: Vector3 = target.global_position
	return Vector2(p.x - point.x, p.z - point.z).length()


func interact(player: Player) -> void:
	if enabled:
		interacted.emit(player)
