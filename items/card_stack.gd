class_name CardStack
extends RefCounted
## What sits in an inventory slot: a card, and a count (aces stack).

var card: CardData
var count: int = 1
## Extra flat stats added to this particular card (K♦ Absorb).
var bonus_stats: Array[CardStat] = []
## Live effect while held (managed by CardInventory).
var effect_instance: CardEffectInstance


func _init(p_card: CardData, p_count: int = 1) -> void:
	card = p_card
	count = p_count


## A copy for working edits (e.g. the pickup screen), keeping bonus stats and
## the live effect instance.
func copy() -> CardStack:
	var stack: CardStack = CardStack.new(card, count)
	stack.bonus_stats = bonus_stats.duplicate()
	stack.effect_instance = effect_instance
	return stack


func all_stats() -> Array[CardStat]:
	var lines: Array[CardStat] = card.stats.duplicate()
	lines.append_array(bonus_stats)
	return lines
