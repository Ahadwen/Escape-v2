extends "res://tests/framework/test_case.gd"

const ChunkGeneratorScript := preload("res://world/streaming/chunk_generator.gd")
const TerrainProfileScript := preload("res://world/streaming/terrain_profile.gd")

var profile: TerrainProfile


func before_each() -> void:
	profile = TerrainProfileScript.new()


func _layout_signature(layout: ChunkLayout) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for o: ChunkLayout.ObstacleSpec in layout.obstacles:
		parts.append("%s@%s/%f" % [o.kind, o.position, o.yaw])
	for p: ChunkLayout.PoiSpec in layout.pois:
		parts.append("%s@%s#%s" % [p.kind, p.position, p.id])
	return "|".join(parts)


func test_same_inputs_give_same_layout() -> void:
	var a: ChunkGenerator = ChunkGeneratorScript.new(profile, 1234, 0)
	var b: ChunkGenerator = ChunkGeneratorScript.new(profile, 1234, 0)
	for coord: Vector2i in [Vector2i(0, 0), Vector2i(3, -2), Vector2i(-7, 11)]:
		assert_eq(_layout_signature(a.generate(coord)), _layout_signature(b.generate(coord)))


func test_different_seeds_differ() -> void:
	var a: ChunkGenerator = ChunkGeneratorScript.new(profile, 1, 0)
	var b: ChunkGenerator = ChunkGeneratorScript.new(profile, 2, 0)
	assert_ne(
		_layout_signature(a.generate(Vector2i(4, 4))), _layout_signature(b.generate(Vector2i(4, 4)))
	)


func test_start_area_is_clear() -> void:
	for run_seed: int in [1, 2, 3, 4, 5]:
		var gen: ChunkGenerator = ChunkGeneratorScript.new(profile, run_seed, 0)
		for o: ChunkLayout.ObstacleSpec in gen.generate(Vector2i.ZERO).obstacles:
			var reach: float = Vector2(o.position.x, o.position.z).length() - o.footprint_radius()
			assert_true(reach >= profile.start_clear_radius, "obstacle too close: %s" % o.position)


func test_obstacles_stay_inside_chunk_with_gap() -> void:
	var gen: ChunkGenerator = ChunkGeneratorScript.new(profile, 99, 0)
	var limit: float = profile.chunk_size * 0.5 - profile.obstacle_gap * 0.5 + 0.001
	for x: int in range(-2, 3):
		for y: int in range(-2, 3):
			for o: ChunkLayout.ObstacleSpec in gen.generate(Vector2i(x, y)).obstacles:
				var r: float = o.footprint_radius()
				assert_true(absf(o.position.x) + r <= limit and absf(o.position.z) + r <= limit)


func test_obstacles_keep_gap_from_each_other() -> void:
	var gen: ChunkGenerator = ChunkGeneratorScript.new(profile, 7, 0)
	var obstacles: Array[ChunkLayout.ObstacleSpec] = gen.generate(Vector2i(5, 1)).obstacles
	for i: int in obstacles.size():
		for j: int in range(i + 1, obstacles.size()):
			var a: ChunkLayout.ObstacleSpec = obstacles[i]
			var b: ChunkLayout.ObstacleSpec = obstacles[j]
			var d: float = (
				Vector2(a.position.x - b.position.x, a.position.z - b.position.z).length()
			)
			assert_true(
				d >= a.footprint_radius() + b.footprint_radius() + profile.obstacle_gap - 0.001
			)


func test_no_safehouses_near_start() -> void:
	var gen: ChunkGenerator = ChunkGeneratorScript.new(profile, 42, 0)
	var r: int = profile.safehouse_min_distance - 1
	for x: int in range(-r, r + 1):
		for y: int in range(-r, r + 1):
			for p: ChunkLayout.PoiSpec in gen.generate(Vector2i(x, y)).pois:
				assert_ne(p.kind, ChunkLayout.POI_SAFEHOUSE, "safehouse at %d,%d" % [x, y])


func test_poi_ids_are_unique_and_stable() -> void:
	var gen: ChunkGenerator = ChunkGeneratorScript.new(profile, 3, 0)
	var seen: Dictionary = {}
	for x: int in range(0, 12):
		for p: ChunkLayout.PoiSpec in gen.generate(Vector2i(x, 6)).pois:
			assert_false(seen.has(p.id), "duplicate id %s" % p.id)
			seen[p.id] = true


func test_coord_for_centres_chunk_zero_on_origin() -> void:
	assert_eq(ChunkGeneratorScript.coord_for(Vector3.ZERO, 32.0), Vector2i(0, 0))
	assert_eq(ChunkGeneratorScript.coord_for(Vector3(15.9, 0, -15.9), 32.0), Vector2i(0, 0))
	assert_eq(ChunkGeneratorScript.coord_for(Vector3(16.1, 0, 0), 32.0), Vector2i(1, 0))
	assert_eq(ChunkGeneratorScript.coord_for(Vector3(-16.1, 0, -50), 32.0), Vector2i(-1, -2))


func test_chunk_distance_is_chebyshev() -> void:
	assert_eq(ChunkGeneratorScript.chunk_distance(Vector2i(0, 0), Vector2i(3, -1)), 3)


func test_compound_cluster_leaves_walkable_gaps() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	for s: int in 20:
		rng.seed = s
		var pieces: Array[ChunkLayout.ObstacleSpec] = ChunkGenerator.compound_cluster(rng)
		for a: int in pieces.size():
			for b: int in range(a + 1, pieces.size()):
				var apart: float = (
					Vector2(
						pieces[a].position.x - pieces[b].position.x,
						pieces[a].position.z - pieces[b].position.z
					)
					. length()
				)
				var edges: float = (pieces[a].size.x + pieces[b].size.x) * 0.5
				assert_true(apart - edges >= 1.0, "gap %.2f" % (apart - edges))


func test_compound_corner_is_two_meeting_walls() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 3
	var pieces: Array[ChunkLayout.ObstacleSpec] = ChunkGenerator.compound_corner(rng)
	assert_eq(pieces.size(), 2)
	assert_almost_eq(pieces[0].yaw, pieces[1].yaw)


func test_safehouses_are_rare_and_spread_out() -> void:
	var gen: ChunkGenerator = ChunkGeneratorScript.new(profile, 42, 0)
	var size: int = profile.safehouse_cell_size
	var per_cell: Dictionary = {}
	var total: int = 0
	for x: int in range(-20, 20):
		for y: int in range(-20, 20):
			if not gen.is_safehouse_chunk(Vector2i(x, y)):
				continue
			total += 1
			assert_true(
				(
					ChunkGenerator.chunk_distance(Vector2i(x, y), Vector2i.ZERO)
					>= profile.safehouse_min_distance
				),
				"not near the start"
			)
			var cell: Vector2i = Vector2i(floori(x / float(size)), floori(y / float(size)))
			assert_false(per_cell.has(cell), "at most one per cell")
			per_cell[cell] = true
	# 1600 chunks = 64 cells; about 80% of them hold one.
	assert_true(total >= 35 and total <= 64, "safehouses: %d" % total)


func test_safehouse_chunk_gets_a_safehouse_poi() -> void:
	var gen: ChunkGenerator = ChunkGeneratorScript.new(profile, 42, 0)
	for x: int in range(5, 30):
		for y: int in range(-10, 10):
			var coord: Vector2i = Vector2i(x, y)
			if not gen.is_safehouse_chunk(coord):
				continue
			var kinds: Array[StringName] = []
			for poi: ChunkLayout.PoiSpec in gen.generate(coord).pois:
				kinds.append(poi.kind)
			assert_true(ChunkLayout.POI_SAFEHOUSE in kinds, "safehouse placed in %s" % coord)
			return
	fail("no safehouse chunk found")
