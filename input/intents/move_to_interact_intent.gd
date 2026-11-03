class_name MoveToInteractIntent
extends PlayerIntent
## Walk to an interactable and interact on arrival (PC right-click on it).

var target: Interactable


func _init(p_target: Interactable) -> void:
	target = p_target
