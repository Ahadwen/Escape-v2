class_name UpgradeAce
extends AceEffect
## A♦: on the card pickup screen, reroll the offered card into the same suit
## one rank higher. Does nothing in the field.


func is_pickup_screen_only() -> bool:
	return true
