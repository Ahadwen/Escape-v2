extends "res://tests/framework/test_case.gd"


func _layout() -> ChunkLayout:
	var layout: ChunkLayout = ChunkLayout.new()
	layout.coord = Vector2i(2, -1)
	layout.obstacles.append(
		ChunkLayout.ObstacleSpec.new(&"box", Vector3(2, 2, 2), Vector3(1, 1, 1), 0.0)
	)
	layout.obstacles.append(
		ChunkLayout.ObstacleSpec.new(&"box", Vector3(2, 2, 2), Vector3(-5, 1, 3), 0.0)
	)
	return layout


func _obstacles(chunk: Node3D) -> Array[Node]:
	var found: Array[Node] = []
	for child: Node in chunk.get_children():
		if child.is_in_group(Obstacles.GROUP):
			found.append(child)
	return found


func test_obstacles_are_destructible_with_stable_ids() -> void:
	var builder: ChunkBuilder = ChunkBuilder.new(null, null, null, Color.GRAY)
	var chunk: Node3D = add_to_tree(builder.build(_layout(), 32.0, Callable(), Callable()))
	var obstacles: Array[Node] = _obstacles(chunk)
	assert_eq(obstacles.size(), 2)
	assert_eq(
		obstacles[1].get_meta(Obstacles.ID_META), ChunkBuilder.obstacle_id(Vector2i(2, -1), 1)
	)
	assert_true(Obstacles.is_destructible(obstacles[0]))


func test_destroyed_obstacles_are_not_rebuilt() -> void:
	var builder: ChunkBuilder = ChunkBuilder.new(null, null, null, Color.GRAY)
	var gone: String = ChunkBuilder.obstacle_id(Vector2i(2, -1), 0)
	var skip: Callable = func(id: String) -> bool: return id == gone
	var chunk: Node3D = add_to_tree(builder.build(_layout(), 32.0, skip, Callable()))
	var obstacles: Array[Node] = _obstacles(chunk)
	assert_eq(obstacles.size(), 1)
	assert_ne(obstacles[0].get_meta(Obstacles.ID_META), gone)


func test_destroy_removes_from_physics_immediately() -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.add_to_group(Obstacles.GROUP)
	add_to_tree(body)
	Obstacles.destroy(body)
	assert_eq(body.collision_layer, 0)
	assert_false(Obstacles.is_destructible(body))
