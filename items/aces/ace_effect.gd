class_name AceEffect
extends Resource
## What using an Ace does. Subclasses implement use().


## Returns true if the ace was used (and a stack should be consumed).
func use(_player: Player) -> bool:
	return false


## Aces that only work on the card pickup screen (e.g. A♦ Upgrade).
func is_pickup_screen_only() -> bool:
	return false
