class_name FlurryAce
extends AceEffect
## A♣: for a few seconds, your next few casts have a tiny flat cooldown.

@export var casts: int = 4
@export var window: float = 5.0
@export var cooldown: float = 0.2


func use(player: Player) -> bool:
	player.abilities.start_flurry(casts, window, cooldown)
	return true
