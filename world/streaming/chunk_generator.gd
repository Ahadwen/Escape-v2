class_name ChunkGenerator
extends RefCounted
## Generates chunk layouts deterministically from (run seed, level, chunk
## coordinate). Pure: no nodes, so it's unit-tested directly.

## kind -> [size, weight, can_rotate]
const OBSTACLE_KINDS: Dictionary = {
	&"pillar": [Vector3(2, 2, 2), 4.0, false],
	&"wall": [Vector3(8, 2, 1), 3.0, true],
	&"longwall": [Vector3(12, 2, 1), 1.0, true],
	&"block": [Vector3(4, 2, 4), 2.0, false],
	&"slab": [Vector3(6, 2, 3), 2.0, true],
}
const ROTATIONS: Array[float] = [0.0, 0.0, PI * 0.5, PI * 0.5, PI * 0.25]
const PLACEMENT_ATTEMPTS: int = 40

var profile: TerrainProfile
var run_seed: int
var level: int


func _init(p_profile: TerrainProfile, p_run_seed: int, p_level: int = 0) -> void:
	profile = p_profile
	run_seed = p_run_seed
	level = p_level


## Which chunk a world position falls in. Chunk (0, 0) is centred on the origin.
static func coord_for(position: Vector3, chunk_size: float) -> Vector2i:
	return Vector2i(
		floori((position.x + chunk_size * 0.5) / chunk_size),
		floori((position.z + chunk_size * 0.5) / chunk_size)
	)


static func chunk_center(coord: Vector2i, chunk_size: float) -> Vector3:
	return Vector3(coord.x * chunk_size, 0.0, coord.y * chunk_size)


## Chebyshev distance in chunks.
static func chunk_distance(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


func seed_for(coord: Vector2i) -> int:
	var h: int = run_seed * 73856093
	h = h ^ (level * 19349663)
	h = h ^ (coord.x * 83492791)
	h = h ^ (coord.y * 2654435761)
	return h


func generate(coord: Vector2i) -> ChunkLayout:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_for(coord)
	var layout: ChunkLayout = ChunkLayout.new()
	layout.coord = coord
	var tint: float = rng.randf()
	layout.ground_color = profile.ground_color_a.lerp(profile.ground_color_b, tint)

	var keepouts: Array[Vector3] = []  # (x, z, radius) packed as Vector3
	var center: Vector3 = chunk_center(coord, profile.chunk_size)
	# Keep the level start clear.
	var start_local: Vector3 = -center
	if start_local.length() < profile.chunk_size:
		keepouts.append(Vector3(start_local.x, start_local.z, profile.start_clear_radius))

	_place_pois(rng, layout, coord, keepouts)
	_place_obstacles(rng, layout, keepouts)
	return layout


func _place_pois(
	rng: RandomNumberGenerator, layout: ChunkLayout, coord: Vector2i, keepouts: Array[Vector3]
) -> void:
	var distance: int = chunk_distance(coord, Vector2i.ZERO)
	if rng.randf() < profile.safehouse_chance(distance):
		_add_poi(rng, layout, coord, ChunkLayout.POI_SAFEHOUSE, keepouts)
	if coord != Vector2i.ZERO and rng.randf() < profile.crystal_chance:
		_add_poi(rng, layout, coord, ChunkLayout.POI_CRYSTAL, keepouts)
	if rng.randf() < profile.chest_chance:
		_add_poi(rng, layout, coord, ChunkLayout.POI_CHEST, keepouts)


func _add_poi(
	rng: RandomNumberGenerator,
	layout: ChunkLayout,
	coord: Vector2i,
	kind: StringName,
	keepouts: Array[Vector3]
) -> void:
	var margin: float = profile.poi_clearance + 1.0
	var half: float = profile.chunk_size * 0.5 - margin
	for attempt: int in PLACEMENT_ATTEMPTS:
		var x: float = rng.randf_range(-half, half)
		var z: float = rng.randf_range(-half, half)
		if _blocked(x, z, profile.poi_clearance, keepouts):
			continue
		var id: String = "%d,%d:%s:%d" % [coord.x, coord.y, kind, layout.pois.size()]
		layout.pois.append(ChunkLayout.PoiSpec.new(kind, Vector3(x, 0.0, z), id))
		keepouts.append(Vector3(x, z, profile.poi_clearance))
		return


func _place_obstacles(
	rng: RandomNumberGenerator, layout: ChunkLayout, keepouts: Array[Vector3]
) -> void:
	var count: int = rng.randi_range(profile.obstacles_min, profile.obstacles_max)
	var kinds: Array = OBSTACLE_KINDS.keys()
	var total_weight: float = 0.0
	for kind: StringName in kinds:
		total_weight += OBSTACLE_KINDS[kind][1]
	for i: int in count:
		var kind: StringName = _pick_kind(rng, kinds, total_weight)
		var info: Array = OBSTACLE_KINDS[kind]
		var size: Vector3 = info[0]
		var can_rotate: bool = info[2]
		var yaw: float = ROTATIONS[rng.randi() % ROTATIONS.size()] if can_rotate else 0.0
		var spec: ChunkLayout.ObstacleSpec = ChunkLayout.ObstacleSpec.new(
			kind, size, Vector3.ZERO, yaw
		)
		var radius: float = spec.footprint_radius()
		# Inset by radius + half the gap, so neighbouring chunks keep the gap too.
		var half: float = profile.chunk_size * 0.5 - radius - profile.obstacle_gap * 0.5
		if half <= 0.0:
			continue
		for attempt: int in PLACEMENT_ATTEMPTS:
			var x: float = rng.randf_range(-half, half)
			var z: float = rng.randf_range(-half, half)
			if _blocked(x, z, radius + profile.obstacle_gap, keepouts):
				continue
			spec.position = Vector3(x, size.y * 0.5, z)
			layout.obstacles.append(spec)
			keepouts.append(Vector3(x, z, radius))
			break


func _pick_kind(rng: RandomNumberGenerator, kinds: Array, total_weight: float) -> StringName:
	var roll: float = rng.randf() * total_weight
	for kind: StringName in kinds:
		roll -= OBSTACLE_KINDS[kind][1]
		if roll < 0.0:
			return kind
	return kinds[-1]


static func _blocked(x: float, z: float, radius: float, keepouts: Array[Vector3]) -> bool:
	for k: Vector3 in keepouts:
		if Vector2(x - k.x, z - k.y).length() < radius + k.z:
			return true
	return false
