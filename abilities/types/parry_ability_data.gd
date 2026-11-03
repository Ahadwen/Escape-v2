class_name ParryAbilityData
extends AbilityData
## Brief parry window: rooted in place and no damage taken. If anything hits
## during it, the parry
## succeeds: nearby enemies are knocked back and stunned and the caster gets a
## big move-speed boost.

## Seconds the parry is up.
@export var window: float = 0.4

@export_group("On success")
@export var knockback_radius: float = 4.5
@export var knockback_distance: float = 4.0
@export var stun_duration: float = 0.6
## Move speed bonus (0.8 = +80%). Typically scales with Will.
@export var speed_scaling: StatScaling
@export var speed_duration: float = 3.0
## Extra invulnerability after a successful parry, so follow-up hits don't
## land in the same instant.
@export var success_grace: float = 0.4


func _init() -> void:
	targeting = Targeting.SELF
	requires_free_movement = true


func create_execution(context: CastContext) -> AbilityExecution:
	return ParryExecution.new(context, self)
