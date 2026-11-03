class_name AreaEffects
extends RefCounted
## Helpers for abilities that affect enemies in an area.


static func enemies_in_radius(tree: SceneTree, center: Vector3, radius: float) -> Array[Enemy]:
	var found: Array[Enemy] = []
	for node: Node in tree.get_nodes_in_group(Enemy.GROUP):
		var enemy: Enemy = node as Enemy
		if enemy == null or enemy.is_despawning():
			continue
		var offset: Vector2 = Vector2(
			enemy.global_position.x - center.x, enemy.global_position.z - center.z
		)
		if offset.length() <= radius:
			found.append(enemy)
	return found


## Flat direction from center to point; a random one if they coincide.
static func away_from(center: Vector3, point: Vector3) -> Vector3:
	var offset: Vector3 = Vector3(point.x - center.x, 0.0, point.z - center.z)
	if offset.length_squared() < 0.0001:
		var angle: float = randf() * TAU
		return Vector3(cos(angle), 0.0, sin(angle))
	return offset.normalized()


## Knocks every enemy in radius away from center and applies a status effect
## made fresh for each one by make_effect (func() -> StatusEffect). Pass an
## invalid Callable() for no effect.
static func knock_back(
	tree: SceneTree, center: Vector3, radius: float, distance: float, make_effect: Callable
) -> int:
	var enemies: Array[Enemy] = enemies_in_radius(tree, center, radius)
	for enemy: Enemy in enemies:
		enemy.apply_knockback(away_from(center, enemy.global_position), distance)
		if make_effect.is_valid():
			var effect: StatusEffect = make_effect.call()
			enemy.apply_status(effect)
	return enemies.size()
