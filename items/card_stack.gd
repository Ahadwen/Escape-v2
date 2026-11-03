class_name CardStack
extends RefCounted
## What sits in an inventory slot: a card, and a count (aces stack).

var card: CardData
var count: int = 1


func _init(p_card: CardData, p_count: int = 1) -> void:
	card = p_card
	count = p_count
