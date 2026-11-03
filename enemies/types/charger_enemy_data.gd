class_name ChargerEnemyData
extends EnemyData
## Closes in, stops, telegraphs a line, then dashes along it. Damages
## anything it runs into during the dash.

## Starts a charge when the target is this close.
@export var charge_trigger_range: float = 8.0
@export var telegraph_time: float = 0.8
@export var charge_distance: float = 10.0
@export var charge_speed: float = 18.0
## Flat distance at which the charge connects.
@export var hit_radius: float = 1.1
## Pause after a charge before chasing again.
@export var recover_time: float = 1.0

@export_group("Fire trail (Inferno)")
@export var fire_trail: bool = false
@export var trail_spacing: float = 1.6
@export var trail_radius: float = 1.0
@export var trail_lifetime: float = 3.0
@export var trail_damage: float = 4.0


func _init() -> void:
	move_speed = 4.2
	damage = 60.0
	lifetime_min = 12.0
	lifetime_max = 18.0


func create_brain() -> EnemyBrain:
	return ChargerBrain.new(self)
