class_name Discoverable
extends Node
## Marks a point of interest as unknown until the player has seen it: it
## comes on screen, or the player gets within reveal_radius. Discoveries are
## stored in the DiscoveryRegistry (if there is one) by poi_id, so they
## persist when the POI's chunk unloads and reloads.

signal discovered

const GROUP: StringName = &"discoverables"
const CHECK_INTERVAL: float = 0.2

@export var target: Node3D
@export var reveal_radius: float = 12.0
@export var show_edge_indicator: bool = true
@export var indicator_color: Color = Color(0.45, 0.8, 1.0)
@export var label: String = ""
## Stable id (set by whoever spawns the POI). Empty = not remembered.
@export var poi_id: String = ""

var is_discovered: bool = false

var _timer: float = 0.0


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	var registry: DiscoveryRegistry = DiscoveryRegistry.find(get_tree())
	if registry != null and not poi_id.is_empty() and registry.is_discovered(poi_id):
		is_discovered = true


func world_position() -> Vector3:
	return target.global_position


func _physics_process(delta: float) -> void:
	if is_discovered or target == null:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = CHECK_INTERVAL
	if _is_seen():
		is_discovered = true
		var registry: DiscoveryRegistry = DiscoveryRegistry.find(get_tree())
		if registry != null and not poi_id.is_empty():
			registry.remember(poi_id, world_position(), indicator_color, label, show_edge_indicator)
		discovered.emit()


func _is_seen() -> bool:
	var position: Vector3 = target.global_position
	var player: Node3D = get_tree().get_first_node_in_group(Player.GROUP) as Node3D
	if player != null:
		var offset: Vector3 = player.global_position - position
		if Vector2(offset.x, offset.z).length() <= reveal_radius:
			return true
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null or not camera.is_position_in_frustum(position):
		return false
	# In the frustum isn't quite on screen for an orthographic camera; check
	# the projected point is inside the visible rect.
	return get_viewport().get_visible_rect().has_point(camera.unproject_position(position))
