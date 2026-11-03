class_name ChargeAbilityData
extends AbilityData
## Charge forward, accelerating and steerable, until hitting something or
## running out of time.

@export var start_speed: float = 6.0
@export var max_speed: float = 16.0
## Metres per second per second.
@export var acceleration: float = 8.0
@export var turn_rate_degrees: float = 35.0
## Seconds.
@export var max_duration: float = 3.0

@export_group("Impact")
@export var impact_radius: float = 2.5
@export var impact_knockback: float = 3.0
@export var impact_stun: float = 0.5


func _init() -> void:
	targeting = Targeting.DIRECTION
	requires_free_movement = true


func create_execution(context: CastContext) -> AbilityExecution:
	return ChargeExecution.new(context, self)
