class_name CycleAceIntent
extends PlayerIntent
## Select the next (+1) or previous (-1) ace stack.

var step: int = 1


func _init(p_step: int) -> void:
	step = p_step
