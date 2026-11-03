class_name CardEffect
extends Resource
## What a T2/T3 card does beyond its stats. A stateless definition: while the
## card is held, create_instance() makes a CardEffectInstance that holds the
## runtime state and hooks into the player.


## Override: return the matching instance class.
func create_instance() -> CardEffectInstance:
	return CardEffectInstance.new()
