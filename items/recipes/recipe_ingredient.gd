class_name RecipeIngredient
extends Resource
## One ingredient: an exact card, or any card of a suit.

## Exact card. If null, any non-ace card of `suit` matches.
@export var card: CardData
@export var suit: CardData.Suit = CardData.Suit.HEARTS


func matches(candidate: CardData) -> bool:
	if candidate == null or candidate.joker or candidate.is_ace():
		return false
	if card != null:
		return candidate.same_card(card)
	return candidate.suit == suit


func is_exact() -> bool:
	return card != null


func describe() -> String:
	return card.label() if card != null else "any %s" % CardData.SUIT_GLYPHS[suit]
