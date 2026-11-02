class_name CastAbilityIntent
extends PlayerIntent
## Cast the ability in a slot (0-3) with the given aim.

var slot: int
var aim: AimData


func _init(p_slot: int, p_aim: AimData) -> void:
	slot = p_slot
	aim = p_aim
