class_name LevelTheme
extends RefCounted
## One level's blend between the neutral zone and the destination zone, at
## an intensity (0 = all neutral, 1 = all destination). Atmosphere blends
## smoothly; obstacles, hazards and enemy variants mix by chance.

var neutral: ZoneData
var zone: ZoneData
var intensity: float = 0.0


func _init(p_neutral: ZoneData, p_zone: ZoneData, p_intensity: float) -> void:
	neutral = p_neutral
	zone = p_zone if p_zone != null else p_neutral
	intensity = clampf(p_intensity, 0.0, 1.0)


func blend_color(a: Color, b: Color) -> Color:
	return a.lerp(b, intensity)


func blend(a: float, b: float) -> float:
	return lerpf(a, b, intensity)


func ground_color(tint: float) -> Color:
	var base: Color = neutral.ground_color_a.lerp(neutral.ground_color_b, tint)
	var target: Color = zone.ground_color_a.lerp(zone.ground_color_b, tint)
	return blend_color(base, target)


## Picks an obstacle kind: from the destination kit with chance = intensity,
## otherwise from the neutral kit.
func pick_obstacle(rng: RandomNumberGenerator) -> ObstacleKind:
	var use_zone: bool = not zone.obstacle_kit.is_empty() and rng.randf() < intensity
	var kit: Array[ObstacleKind] = zone.obstacle_kit if use_zone else neutral.obstacle_kit
	return LevelTheme.pick_weighted(kit, rng.randf())


static func pick_weighted(kit: Array[ObstacleKind], roll: float) -> ObstacleKind:
	if kit.is_empty():
		return null
	var total: float = 0.0
	for kind: ObstacleKind in kit:
		total += kind.weight
	var target: float = clampf(roll, 0.0, 0.999999) * total
	for kind: ObstacleKind in kit:
		target -= kind.weight
		if target < 0.0:
			return kind
	return kit[-1]


## The enemy to actually spawn: the zone variant with chance = intensity.
func enemy_for(base: EnemyData, roll: float) -> EnemyData:
	if base == null or roll >= intensity:
		return base
	var variant: EnemyData = zone.variant_for(base.id)
	return variant if variant != null else base


func hits_ignite() -> bool:
	return zone.hits_ignite and intensity > 0.0
