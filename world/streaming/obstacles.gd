class_name Obstacles
extends RefCounted
## Destructible terrain. Generated obstacles join GROUP and carry a stable id
## so the world streamer can remember which were destroyed.

const GROUP: StringName = &"destructible_obstacles"
const ID_META: StringName = &"obstacle_id"
## Group of the node that owns the terrain (WorldStreamer).
const OWNER_GROUP: StringName = &"terrain_owner"


static func is_destructible(node: Node) -> bool:
	return node != null and node.is_in_group(GROUP)


## Destroys an obstacle: through the terrain owner if there is one (so it
## stays destroyed and navigation is rebuilt), otherwise just removes it.
static func destroy(body: Node3D) -> void:
	if not is_instance_valid(body) or not is_destructible(body):
		return
	var owner_node: Node = body.get_tree().get_first_node_in_group(OWNER_GROUP)
	if owner_node != null and owner_node.has_method(&"destroy_obstacle"):
		owner_node.call(&"destroy_obstacle", body)
		return
	remove(body)


## Takes the obstacle out of physics immediately and frees it.
static func remove(body: Node3D) -> void:
	body.remove_from_group(GROUP)
	if body is CollisionObject3D:
		(body as CollisionObject3D).collision_layer = 0
	body.queue_free()
