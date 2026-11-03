class_name HealthCrystal
extends Area3D
## Restores a fraction of max HP when the player touches it. Used up on use;
## left alone if the player is already at full HP.

@export_range(0.0, 1.0) var heal_fraction: float = 0.25
@export var spin_speed: float = 1.5

var _used: bool = false

@onready var visual: Node3D = $Visual


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2


func _process(delta: float) -> void:
	visual.rotate_y(spin_speed * delta)


func _physics_process(_delta: float) -> void:
	if _used:
		return
	for body: Node3D in get_overlapping_bodies():
		var player: Player = body as Player
		if player == null or player.is_dead:
			continue
		if player.health.heal_fraction(heal_fraction) > 0.0:
			_consume()
			return


func _consume() -> void:
	_used = true
	var tween: Tween = create_tween()
	tween.tween_property(visual, "scale", Vector3.ONE * 0.01, 0.25)
	tween.tween_callback(queue_free)
