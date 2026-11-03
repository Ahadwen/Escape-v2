class_name ArtilleryEnemyData
extends EnemyData
## Keeps well back and lobs shells at where the target is heading. Each shell
## telegraphs its area, detonates, then leaves a lingering zone.

@export var preferred_min: float = 13.0
@export var preferred_max: float = 19.0
@export var fire_range: float = 26.0
## Seconds of target movement to lead by.
@export var lead_time: float = 0.8
@export var strike_radius: float = 3.1
## Telegraph time before detonation.
@export var strike_wind_up: float = 1.3
@export var linger_duration: float = 2.5
@export var linger_damage: float = 8.0
@export var linger_interval: float = 0.5


func _init() -> void:
	move_speed = 4.5
	damage = 45.0
	attack_cooldown = 3.2
	sight_range = 26.0
	lose_interest_range = 32.0
	body_scale = Vector3(1.15, 0.85, 1.15)


func create_brain() -> EnemyBrain:
	return ArtilleryBrain.new(self)
