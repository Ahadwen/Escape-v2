class_name HunterAction
extends RefCounted
## A hunter ability in progress (wind-up, effect, recovery). While an action
## runs the hunter doesn't chase.

var brain: HunterBrain


func _init(p_brain: HunterBrain) -> void:
	brain = p_brain


func enemy() -> Enemy:
	return brain.enemy


func start() -> void:
	pass


## Returns true when finished.
func tick(_delta: float) -> bool:
	return true


## Interrupted (knockback, stun) or the hunter is leaving.
func cancel() -> void:
	pass
