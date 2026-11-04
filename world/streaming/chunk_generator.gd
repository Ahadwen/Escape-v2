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
## Optional. If set, obstacles and ground colours come from the level theme.
var theme: LevelTheme


func _init(
	p_profile: TerrainProfile, p_run_seed: int, p_level: int = 0, p_theme: LevelTheme = null
) -> void:
	profile = p_profile
	run_seed = p_run_seed
	level = p_level
	theme = p_theme


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
	if theme != null:
		layout.ground_color = theme.ground_color(tint)
	else:
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
		if rng.randf() < profile.compound_chance:
			_place_compound(rng, layout, keepouts)
			continue
		var spec: ChunkLayout.ObstacleSpec = _roll_obstacle(rng, kinds, total_weight)
		var size: Vector3 = spec.size
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


## Places an L-shaped corner or a cluster of pillars as one unit (one
## keepout, so the usual gap stays around it).
func _place_compound(
	rng: RandomNumberGenerator, layout: ChunkLayout, keepouts: Array[Vector3]
) -> void:
	var color: Color = profile.obstacle_color
	if theme != null:
		var themed: ObstacleKind = theme.pick_obstacle(rng)
		if themed != null:
			color = themed.color
	var pieces: Array[ChunkLayout.ObstacleSpec] = (
		compound_corner(rng) if rng.randf() < 0.6 else compound_cluster(rng)
	)
	var radius: float = 0.0
	for piece: ChunkLayout.ObstacleSpec in pieces:
		var reach: float = Vector2(piece.position.x, piece.position.z).length()
		radius = maxf(radius, reach + piece.footprint_radius())
	var half: float = profile.chunk_size * 0.5 - radius - profile.obstacle_gap * 0.5
	if half <= 0.0:
		return
	for attempt: int in PLACEMENT_ATTEMPTS:
		var x: float = rng.randf_range(-half, half)
		var z: float = rng.randf_range(-half, half)
		if _blocked(x, z, radius + profile.obstacle_gap, keepouts):
			continue
		for piece: ChunkLayout.ObstacleSpec in pieces:
			piece.position += Vector3(x, 0.0, z)
			piece.color = color
			layout.obstacles.append(piece)
		keepouts.append(Vector3(x, z, radius))
		return


## Two walls meeting at a corner, turned to one of four directions. Pieces
## are positioned relative to the corner's centre.
static func compound_corner(rng: RandomNumberGenerator) -> Array[ChunkLayout.ObstacleSpec]:
	var yaw: float = PI * 0.5 * rng.randi_range(0, 3)
	var long: float = rng.randf_range(7.0, 10.0)
	var short: float = rng.randf_range(4.0, 7.0)
	var a: ChunkLayout.ObstacleSpec = ChunkLayout.ObstacleSpec.new(
		&"corner", Vector3(long, 2.0, 1.0), Vector3(long * 0.5, 1.0, 0.0), yaw
	)
	var b: ChunkLayout.ObstacleSpec = ChunkLayout.ObstacleSpec.new(
		&"corner", Vector3(1.0, 2.0, short), Vector3(0.0, 1.0, short * 0.5 - 0.5), yaw
	)
	var pieces: Array[ChunkLayout.ObstacleSpec] = [a, b]
	# Centre the shape on the middle of its footprint, then turn it.
	var middle: Vector3 = Vector3(long * 0.25, 0.0, short * 0.25)
	for piece: ChunkLayout.ObstacleSpec in pieces:
		var local: Vector3 = piece.position - middle
		piece.position = (
			Vector3(0.0, piece.position.y, 0.0)
			+ Vector3(local.x, 0.0, local.z).rotated(Vector3.UP, yaw)
		)
	return pieces


## Three or four pillars packed close, with narrow gaps between them.
static func compound_cluster(rng: RandomNumberGenerator) -> Array[ChunkLayout.ObstacleSpec]:
	var pieces: Array[ChunkLayout.ObstacleSpec] = []
	var count: int = rng.randi_range(3, 4)
	var turn: float = rng.randf() * TAU
	for i: int in count:
		var angle: float = turn + TAU * i / count
		var size: float = rng.randf_range(1.5, 2.5)
		var offset: Vector3 = Vector3(cos(angle), 0.0, sin(angle)) * 2.6
		pieces.append(
			ChunkLayout.ObstacleSpec.new(
				&"cluster", Vector3(size, 2.0, size), offset + Vector3.UP, 0.0
			)
		)
	return pieces


func _roll_obstacle(
	rng: RandomNumberGenerator, kinds: Array, total_weight: float
) -> ChunkLayout.ObstacleSpec:
	var themed: ObstacleKind = theme.pick_obstacle(rng) if theme != null else null
	if themed != null:
		var themed_yaw: float = (
			ROTATIONS[rng.randi() % ROTATIONS.size()] if themed.can_rotate else 0.0
		)
		var themed_spec: ChunkLayout.ObstacleSpec = ChunkLayout.ObstacleSpec.new(
			themed.kind, themed.size, Vector3.ZERO, themed_yaw
		)
		themed_spec.color = themed.color
		return themed_spec
	var kind: StringName = _pick_kind(rng, kinds, total_weight)
	var info: Array = OBSTACLE_KINDS[kind]
	var can_rotate: bool = info[2]
	var yaw: float = ROTATIONS[rng.randi() % ROTATIONS.size()] if can_rotate else 0.0
	var spec: ChunkLayout.ObstacleSpec = ChunkLayout.ObstacleSpec.new(
		kind, info[0], Vector3.ZERO, yaw
	)
	spec.color = profile.obstacle_color
	return spec


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
