class_name StatBuffAbilityData
extends AbilityData
## Temporarily adds a stat modifier to the caster.

@export var stat: StringName = StatIds.MOVE_SPEED
@export var modifier_type: StatModifier.Type = StatModifier.Type.PERCENT_ADD
## Size of the modifier. For PERCENT types, 0.3 means +30%.
@export var amount_scaling: StatScaling
## Seconds.
@export var duration: float = 3.0


func _init() -> void:
	targeting = Targeting.SELF


func create_execution(context: CastContext) -> AbilityExecution:
	return StatBuffExecution.new(context, self)
