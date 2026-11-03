class_name BlinkAbilityData
extends AbilityData
## Instantly teleport up to range_scaling metres in the aimed direction,
## passing over walls.

## How far past the aimed spot to look for a landing beyond a wall.
@export var max_overshoot: float = 3.0
## Flat distance from the navmesh within which a point counts as walkable.
@export var walkable_tolerance: float = 0.15

@export_group("Landing shockwave")
## Current HP fraction needed for a shockwave on landing.
@export_range(0.0, 1.0) var shockwave_hp_threshold: float = 0.5
## Radius and knockback grow from min (just above threshold) to max (full HP).
@export var shockwave_radius_min: float = 1.5
@export var shockwave_radius_max: float = 3.5
@export var shockwave_knockback_min: float = 1.5
@export var shockwave_knockback_max: float = 3.5
@export_range(0.0, 1.0) var shockwave_slow: float = 0.3
@export var shockwave_slow_duration_min: float = 0.8
@export var shockwave_slow_duration_max: float = 1.5


## 0..1 shockwave strength for an HP fraction, or -1 for no shockwave.
static func shockwave_strength(hp_fraction: float, threshold: float) -> float:
	if hp_fraction <= threshold:
		return -1.0
	if threshold >= 1.0:
		return 1.0
	return clampf(inverse_lerp(threshold, 1.0, hp_fraction), 0.0, 1.0)


func _init() -> void:
	targeting = Targeting.DIRECTION
	requires_free_movement = true


func create_execution(context: CastContext) -> AbilityExecution:
	return BlinkExecution.new(context, self)
