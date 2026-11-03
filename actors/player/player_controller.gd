class_name PlayerController
extends Node
## Turns PlayerIntents into actions on the player's components. Knows nothing
## about devices or control schemes.

@export var movement: ActorMovement
@export var abilities: AbilityCaster

## When false (e.g. dead), all intents are ignored.
var enabled: bool = true


func handle_intent(intent: PlayerIntent) -> void:
	if not enabled:
		return
	if intent is MoveToPointIntent:
		movement.move_to((intent as MoveToPointIntent).point)
	elif intent is MoveDirectionIntent:
		movement.move_in_direction((intent as MoveDirectionIntent).direction)
	elif intent is StopIntent:
		movement.stop()
	elif intent is CastAbilityIntent:
		var cast: CastAbilityIntent = intent as CastAbilityIntent
		abilities.try_cast(cast.slot, cast.aim)
	elif intent is AimIntent:
		abilities.update_aim((intent as AimIntent).aim)
