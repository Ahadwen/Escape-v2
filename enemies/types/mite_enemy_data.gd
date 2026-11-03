class_name MiteEnemyData
extends EnemyData
## Tiny, fast, short-lived swarm enemy spawned by broods. Contact damage only.


func _init() -> void:
	move_speed = 10.5
	contact_damage = 8.0
	contact_cooldown = 0.5
	sight_range = 30.0
	lose_interest_range = 0.0
	lifetime_min = 2.5
	lifetime_max = 3.5
	despawn_warning = 0.6
	speed_gain_over_life = 0.0
	threat_cost = 0.0
	body_scale = Vector3(0.5, 0.45, 0.5)


func create_brain() -> EnemyBrain:
	# The base brain already intercepts, flanks and wanders.
	return EnemyBrain.new()
