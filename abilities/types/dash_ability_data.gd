class_name DashAbilityData
extends AbilityData
## Dash a distance (range_scaling) in the aimed direction.

@export var dash_speed: float = 22.0


func _init() -> void:
	targeting = Targeting.DIRECTION
	requires_free_movement = true


func create_execution(context: CastContext) -> AbilityExecution:
	return DashExecution.new(context, self)
