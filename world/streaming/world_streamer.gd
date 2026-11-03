class_name WorldStreamer
extends Node
## Streams generated chunks in around the player and frees them behind, and
## keeps one navmesh over everything loaded (rebaked on a thread when the
## loaded set changes). Remembers consumed POIs so they stay consumed.

signal safehouse_entered(player: Player)

@export var profile: TerrainProfile
@export var player: Node3D
## Chunks are added under this region so its navmesh bake includes them.
@export var nav_region: NavigationRegion3D
@export var crystal_scene: PackedScene
@export var safehouse_scene: PackedScene

var run_seed: int = 0
var level: int = 0

var _generator: ChunkGenerator
var _builder: ChunkBuilder
var _chunks: Dictionary[Vector2i, Node3D] = {}
var _consumed: Dictionary[String, bool] = {}
var _current: Vector2i = Vector2i(2147483647, 0)
var _nav_dirty: bool = false
var _baking: bool = false


## Generates the area around the player and bakes navigation synchronously,
## so the level is ready the moment this returns.
func start(p_seed: int, p_level: int = 0) -> void:
	run_seed = p_seed
	level = p_level
	_generator = ChunkGenerator.new(profile, run_seed, level)
	_builder = ChunkBuilder.new(crystal_scene, safehouse_scene, profile.obstacle_color)
	nav_region.bake_finished.connect(_on_bake_finished)
	_update_chunks(true)
	nav_region.bake_navigation_mesh(false)
	_nav_dirty = false
	if nav_region.navigation_mesh.get_polygon_count() == 0:
		push_error("Navigation mesh baked with no polygons.")


func current_chunk() -> Vector2i:
	return _current


func loaded_count() -> int:
	return _chunks.size()


func _physics_process(_delta: float) -> void:
	if _generator == null or player == null:
		return
	_update_chunks(false)
	if _nav_dirty and not _baking:
		_nav_dirty = false
		_baking = true
		nav_region.bake_navigation_mesh(true)


func _update_chunks(force: bool) -> void:
	var coord: Vector2i = ChunkGenerator.coord_for(player.global_position, profile.chunk_size)
	if coord == _current and not force:
		return
	_current = coord
	var changed: bool = false
	var r: int = profile.load_radius
	for x: int in range(coord.x - r, coord.x + r + 1):
		for y: int in range(coord.y - r, coord.y + r + 1):
			var c: Vector2i = Vector2i(x, y)
			if not _chunks.has(c):
				_load(c)
				changed = true
	for c: Vector2i in _chunks.keys():
		if ChunkGenerator.chunk_distance(c, coord) > profile.unload_radius:
			_chunks[c].queue_free()
			_chunks.erase(c)
			changed = true
	if changed:
		_nav_dirty = true


func _load(coord: Vector2i) -> void:
	var layout: ChunkLayout = _generator.generate(coord)
	var chunk: Node3D = _builder.build(layout, profile.chunk_size, _is_consumed, _on_poi_built)
	nav_region.add_child(chunk)
	_chunks[coord] = chunk


func _is_consumed(id: String) -> bool:
	return _consumed.has(id)


func _on_poi_built(node: Node3D, spec: ChunkLayout.PoiSpec) -> void:
	if node is HealthCrystal:
		(node as HealthCrystal).consumed.connect(_on_consumed.bind(spec.id))
	elif node is Safehouse:
		(node as Safehouse).entered.connect(_on_safehouse_entered)


func _on_safehouse_entered(who: Player) -> void:
	safehouse_entered.emit(who)


func _on_consumed(id: String) -> void:
	_consumed[id] = true


func _on_bake_finished() -> void:
	_baking = false
