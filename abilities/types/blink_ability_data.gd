class_name BlinkAbilityData
extends AbilityData
## Instantly teleport up to range_scaling metres in the aimed direction,
## passing over walls.

## How far past the aimed spot to look for a landing beyond a wall.
@export var max_overshoot: float = 3.0
## Flat distance from the navmesh within which a point counts as walkable.
@export var walkable_tolerance: float = 0.15


func _init() -> void:
	targeting = Targeting.DIRECTION
	requires_free_movement = true


func create_execution(context: CastContext) -> AbilityExecution:
	return BlinkExecution.new(context, self)
