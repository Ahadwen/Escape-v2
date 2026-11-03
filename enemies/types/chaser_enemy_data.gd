class_name ChaserEnemyData
extends EnemyData
## Slow and relentless: once it has a target it follows forever, and hits
## when in reach after a short wind-up.

@export var attack_range: float = 1.4
## Telegraph time before the hit lands.
@export var wind_up: float = 0.35


func _init() -> void:
	move_speed = 3.8
	lose_interest_range = 0.0


func create_brain() -> EnemyBrain:
	return ChaserBrain.new(self)
