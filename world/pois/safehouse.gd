class_name Safehouse
extends Area3D
## Reaching it ends the level. (Later: a shop, then the next level.)

signal entered(player: Player)

var _triggered: bool = false


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2


func _physics_process(_delta: float) -> void:
	if _triggered:
		return
	for body: Node3D in get_overlapping_bodies():
		var player: Player = body as Player
		if player != null and not player.is_dead:
			_triggered = true
			entered.emit(player)
			return
