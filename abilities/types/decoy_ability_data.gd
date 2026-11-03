class_name DecoyAbilityData
extends AbilityData
## Drop a decoy. With SELF targeting (the default) it appears where the caster
## stands; with POINT targeting it goes to the aimed point within range.
## Enemies prefer it over the player.

@export var decoy_scene: PackedScene
## Decoy HP. Typically scales with Will.
@export var hp_scaling: StatScaling
## Seconds before the decoy fades on its own.
@export var lifetime: float = 4.0


func _init() -> void:
	targeting = Targeting.SELF


func create_execution(context: CastContext) -> AbilityExecution:
	return DecoyExecution.new(context, self)
