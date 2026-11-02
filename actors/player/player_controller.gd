class_name PlayerController
extends Node
## Turns PlayerIntents into actions on the player's components. Knows nothing
## about devices or control schemes.

@export var movement: ActorMovement


func handle_intent(intent: PlayerIntent) -> void:
	if intent is MoveToPointIntent:
		movement.move_to((intent as MoveToPointIntent).point)
	elif intent is MoveDirectionIntent:
		movement.move_in_direction((intent as MoveDirectionIntent).direction)
	elif intent is StopIntent:
		movement.stop()
