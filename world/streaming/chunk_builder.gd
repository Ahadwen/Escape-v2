class_name ChunkBuilder
extends RefCounted
## Turns a ChunkLayout into nodes. Meshes, shapes and materials are shared
## between chunks.

## Physics layer 5 ("ground"): floors, kept separate from walls (layer 1).
const GROUND_LAYER_BIT: int = 16

var crystal_scene: PackedScene
var safehouse_scene: PackedScene
var chest_scene: PackedScene
var obstacle_color: Color

var _meshes: Dictionary[String, BoxMesh] = {}
var _shapes: Dictionary[String, BoxShape3D] = {}
var _materials: Dictionary[String, StandardMaterial3D] = {}
var _floor_shape: BoxShape3D
var _floor_mesh: BoxMesh


func _init(
	p_crystal: PackedScene, p_safehouse: PackedScene, p_chest: PackedScene, p_obstacle_color: Color
) -> void:
	crystal_scene = p_crystal
	safehouse_scene = p_safehouse
	chest_scene = p_chest
	obstacle_color = p_obstacle_color


## Stable id of a chunk's i-th obstacle (used to remember destroyed ones).
static func obstacle_id(coord: Vector2i, index: int) -> String:
	return "obstacle_%d_%d_%d" % [coord.x, coord.y, index]


## Builds the chunk. skip_poi(id) -> bool lets the caller drop consumed POIs
## and destroyed obstacles.
## on_poi(node, spec) is called for each POI node created.
func build(layout: ChunkLayout, chunk_size: float, skip_poi: Callable, on_poi: Callable) -> Node3D:
	var chunk: Node3D = Node3D.new()
	chunk.name = "Chunk_%d_%d" % [layout.coord.x, layout.coord.y]
	chunk.position = ChunkGenerator.chunk_center(layout.coord, chunk_size)
	chunk.add_child(_build_floor(layout, chunk_size))
	for i: int in layout.obstacles.size():
		var id: String = obstacle_id(layout.coord, i)
		if skip_poi.is_valid() and skip_poi.call(id):
			continue
		var obstacle: StaticBody3D = _build_obstacle(layout.obstacles[i])
		obstacle.set_meta(Obstacles.ID_META, id)
		obstacle.add_to_group(Obstacles.GROUP)
		chunk.add_child(obstacle)
	for poi: ChunkLayout.PoiSpec in layout.pois:
		if skip_poi.is_valid() and skip_poi.call(poi.id):
			continue
		var node: Node3D = _build_poi(poi)
		if node == null:
			continue
		chunk.add_child(node)
		if on_poi.is_valid():
			on_poi.call(node, poi)
	return chunk


func _build_floor(layout: ChunkLayout, chunk_size: float) -> StaticBody3D:
	if _floor_shape == null:
		_floor_shape = BoxShape3D.new()
		_floor_shape.size = Vector3(chunk_size, 1.0, chunk_size)
		_floor_mesh = BoxMesh.new()
		_floor_mesh.size = _floor_shape.size
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "Floor"
	body.position = Vector3(0.0, -0.5, 0.0)
	body.collision_layer = GROUND_LAYER_BIT
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.shape = _floor_shape
	body.add_child(shape)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.mesh = _floor_mesh
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = layout.ground_color
	mesh.material_override = material
	body.add_child(mesh)
	return body


func _build_obstacle(spec: ChunkLayout.ObstacleSpec) -> StaticBody3D:
	var key: String = "%s|%s|%s" % [spec.kind, spec.size, spec.color.to_html()]
	if not _meshes.has(key):
		var color_key: String = spec.color.to_html()
		if not _materials.has(color_key):
			var material: StandardMaterial3D = StandardMaterial3D.new()
			material.albedo_color = spec.color
			_materials[color_key] = material
		var box: BoxMesh = BoxMesh.new()
		box.size = spec.size
		box.material = _materials[color_key]
		_meshes[key] = box
		var shape: BoxShape3D = BoxShape3D.new()
		shape.size = spec.size
		_shapes[key] = shape
	var body: StaticBody3D = StaticBody3D.new()
	body.position = spec.position
	body.rotation.y = spec.yaw
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = _shapes[key]
	body.add_child(collision)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.mesh = _meshes[key]
	body.add_child(mesh)
	return body


func _build_poi(poi: ChunkLayout.PoiSpec) -> Node3D:
	var scene: PackedScene = null
	match poi.kind:
		ChunkLayout.POI_CRYSTAL:
			scene = crystal_scene
		ChunkLayout.POI_SAFEHOUSE:
			scene = safehouse_scene
		ChunkLayout.POI_CHEST:
			scene = chest_scene
	if scene == null:
		return null
	var node: Node3D = scene.instantiate() as Node3D
	node.position = poi.position
	var discoverable: Discoverable = node.get_node_or_null("Discoverable") as Discoverable
	if discoverable != null:
		discoverable.poi_id = poi.id
	return node
