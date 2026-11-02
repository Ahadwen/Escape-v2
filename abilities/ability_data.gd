class_name AbilityData
extends Resource
## Base for ability definitions. Subclasses add their parameters and create
## the matching AbilityExecution. Never store per-cast state here.

enum Targeting { NONE, SELF, DIRECTION, POINT }

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
@export var targeting: Targeting = Targeting.NONE
## Seconds, starting when the execution finishes.
@export var cooldown: float = 5.0
## Optional. Range in metres for DIRECTION and POINT abilities.
@export var range_scaling: StatScaling
## If true, can't be cast while a dash/charge/knockback is moving the caster.
@export var requires_free_movement: bool = false


func get_range(stats: StatBlock) -> float:
	return range_scaling.evaluate(stats) if range_scaling != null else 0.0


## Override in subclasses.
func create_execution(context: CastContext) -> AbilityExecution:
	return AbilityExecution.new(context)
