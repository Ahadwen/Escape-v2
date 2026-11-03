class_name SpinnerEnemyData
extends EnemyData
## A spinning top: charges at where the target is heading, wobbles to a stop,
## then charges again. Damages anything it touches.

@export var charge_speed: float = 19.0
## Keeps going this much further than the aimed point (0.5 = +50%).
@export var overshoot_ratio: float = 0.5
@export var max_charge_distance: float = 24.0
## Slows down over this final fraction of the charge.
@export var decay_fraction: float = 0.2
## How far ahead to aim, in seconds of target movement.
@export var lead_time: float = 0.35
@export var teeter_min: float = 0.9
@export var teeter_max: float = 1.4
## Visual spin, radians per second.
@export var spin_speed: float = 22.0


func _init() -> void:
	contact_damage = 25.0
	contact_cooldown = 0.8
	lose_interest_range = 30.0
	body_scale = Vector3(1.4, 0.55, 1.4)


func create_brain() -> EnemyBrain:
	return SpinnerBrain.new(self)
