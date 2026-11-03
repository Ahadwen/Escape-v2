class_name UseAceIntent
extends PlayerIntent
## Use an ace: either ace stack number `ace_index` (PC keys 1-4) or, if -1,
## the currently selected ace (gamepad / touch).

var ace_index: int = -1


func _init(p_ace_index: int = -1) -> void:
	ace_index = p_ace_index
