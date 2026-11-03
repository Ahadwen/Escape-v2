class_name RecoverAce
extends AceEffect
## A♥: heal all damage taken in the last `window` seconds, over `duration`.

@export var window: float = 1.5
@export var duration: float = 6.0


func use(player: Player) -> bool:
	var amount: float = player.health.damage_in_last(window)
	if amount > 0.0:
		player.status.apply(HealOverTimeEffect.new(amount, duration, &"ace_recover"))
	return true
