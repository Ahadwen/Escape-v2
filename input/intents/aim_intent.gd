class_name AimIntent
extends PlayerIntent
## Continuous aim update, used to steer abilities that are already running.

var aim: AimData


func _init(p_aim: AimData) -> void:
	aim = p_aim
