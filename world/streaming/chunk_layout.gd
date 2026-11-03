class_name ChunkLayout
extends RefCounted
## Plain-data description of one generated chunk. Positions are relative to
## the chunk centre.


class ObstacleSpec:
	var kind: StringName
	var size: Vector3
	var position: Vector3
	var yaw: float

	func _init(p_kind: StringName, p_size: Vector3, p_position: Vector3, p_yaw: float) -> void:
		kind = p_kind
		size = p_size
		position = p_position
		yaw = p_yaw

	## Radius of a circle that contains the obstacle's footprint.
	func footprint_radius() -> float:
		return Vector2(size.x, size.z).length() * 0.5


class PoiSpec:
	var kind: StringName
	var position: Vector3
	## Stable across visits: used to remember consumed/discovered POIs.
	var id: String

	func _init(p_kind: StringName, p_position: Vector3, p_id: String) -> void:
		kind = p_kind
		position = p_position
		id = p_id


const POI_CRYSTAL: StringName = &"crystal"
const POI_SAFEHOUSE: StringName = &"safehouse"

var coord: Vector2i
var ground_color: Color
var obstacles: Array[ObstacleSpec] = []
var pois: Array[PoiSpec] = []
