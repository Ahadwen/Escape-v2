extends "res://tests/framework/test_case.gd"

const TargetableScript := preload("res://actors/components/targetable.gd")


func _make(position: Vector3, priority: int, faction: Targetable.Faction) -> Targetable:
	var body: Node3D = add_to_tree(Node3D.new()) as Node3D
	body.global_position = position
	var targetable: Targetable = TargetableScript.new()
	targetable.body = body
	targetable.priority = priority
	targetable.faction = faction
	body.add_child(targetable)
	return targetable


func test_picks_nearest_of_equal_priority() -> void:
	var far: Targetable = _make(Vector3(8, 0, 0), 0, Targetable.Faction.PLAYER)
	var near: Targetable = _make(Vector3(3, 0, 0), 0, Targetable.Faction.PLAYER)
	var candidates: Array[Targetable] = [far, near]
	var best: Targetable = TargetableScript.pick_best(
		candidates, Vector3.ZERO, Targetable.Faction.PLAYER, 20.0
	)
	assert_eq(best, near)


func test_higher_priority_beats_distance() -> void:
	var player: Targetable = _make(Vector3(2, 0, 0), 0, Targetable.Faction.PLAYER)
	var decoy: Targetable = _make(Vector3(9, 0, 0), 10, Targetable.Faction.PLAYER)
	var candidates: Array[Targetable] = [player, decoy]
	var best: Targetable = TargetableScript.pick_best(
		candidates, Vector3.ZERO, Targetable.Faction.PLAYER, 20.0
	)
	assert_eq(best, decoy)


func test_out_of_range_is_ignored() -> void:
	var decoy: Targetable = _make(Vector3(30, 0, 0), 10, Targetable.Faction.PLAYER)
	var player: Targetable = _make(Vector3(5, 0, 0), 0, Targetable.Faction.PLAYER)
	var candidates: Array[Targetable] = [decoy, player]
	var best: Targetable = TargetableScript.pick_best(
		candidates, Vector3.ZERO, Targetable.Faction.PLAYER, 20.0
	)
	assert_eq(best, player)


func test_other_faction_is_ignored() -> void:
	var enemy: Targetable = _make(Vector3(1, 0, 0), 0, Targetable.Faction.ENEMY)
	var candidates: Array[Targetable] = [enemy]
	assert_null(
		TargetableScript.pick_best(candidates, Vector3.ZERO, Targetable.Faction.PLAYER, 20.0)
	)


func test_distance_is_flat() -> void:
	var high: Targetable = _make(Vector3(3, 50, 4), 0, Targetable.Faction.PLAYER)
	assert_almost_eq(high.flat_distance_to(Vector3.ZERO), 5.0)
