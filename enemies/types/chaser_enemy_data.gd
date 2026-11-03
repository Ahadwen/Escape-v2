class_name ChaserEnemyData
extends EnemyData
## Relentless pursuer: intercepts and flanks, and when close winds up a short
## telegraphed lunge.

## Starts winding up a lunge when the target is this close.
@export var lunge_trigger_range: float = 4.0
## Telegraph time before the lunge.
@export var wind_up: float = 0.3
@export var lunge_distance: float = 4.5
@export var lunge_speed: float = 20.0
## Flat distance at which the lunge connects.
@export var hit_radius: float = 1.0


func _init() -> void:
	move_speed = 6.5
	lose_interest_range = 0.0


func create_brain() -> EnemyBrain:
	return ChaserBrain.new(self)
