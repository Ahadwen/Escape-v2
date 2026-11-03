class_name GunnerEnemyData
extends EnemyData
## Holds a distance band from the target and fires straight-line shots when it
## has line of sight.

@export var preferred_min: float = 9.0
@export var preferred_max: float = 13.0
## Won't shoot beyond this.
@export var fire_range: float = 18.0
## Brief aim line before each shot.
@export var aim_time: float = 0.35
@export var projectile_speed: float = 21.0
@export var projectile_radius: float = 0.3
## Inferno: fire an expanding cone of flame instead of a bullet.
@export var flame_cone: bool = false


func _init() -> void:
	move_speed = 5.5
	damage = 20.0
	attack_cooldown = 1.4
	sight_range = 22.0
	lose_interest_range = 28.0


func create_brain() -> EnemyBrain:
	return GunnerBrain.new(self)
