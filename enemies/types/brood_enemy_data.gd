class_name BroodEnemyData
extends EnemyData
## Big, slow and fat. Lumbers after the target and keeps spawning swarms of
## mites around itself.

@export var minion: EnemyData
@export var first_spawn_delay: float = 1.5
@export var spawn_interval: float = 1.6
@export var spawn_count: int = 3
@export var max_minions: int = 10
@export var spawn_radius: float = 1.8


func _init() -> void:
	move_speed = 3.2
	contact_damage = 20.0
	contact_cooldown = 1.0
	sight_range = 22.0
	lose_interest_range = 0.0
	threat_cost = 3.0
	body_scale = Vector3(1.9, 1.35, 1.9)


func create_brain() -> EnemyBrain:
	return BroodBrain.new(self)
