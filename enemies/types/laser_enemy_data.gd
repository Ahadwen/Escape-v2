class_name LaserEnemyData
extends EnemyData
## Gets within range with line of sight, primes a locked warning line, then
## fires a beam along it.

@export var fire_range: float = 15.0
@export var prime_time: float = 0.65
@export var beam_length: float = 24.0
@export var beam_half_width: float = 0.35
## Seconds of target movement to lead by when locking the line.
@export var lead_time: float = 0.3


func _init() -> void:
	move_speed = 5.0
	damage = 50.0
	damage_type = DamageEvent.DamageType.ELEMENTAL
	attack_cooldown = 2.2
	sight_range = 22.0
	lose_interest_range = 28.0


func create_brain() -> EnemyBrain:
	return LaserBrain.new(self)
