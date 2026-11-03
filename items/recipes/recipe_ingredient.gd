class_name RecipeIngredient
extends Resource
## One ingredient: a card of a given rank (any suit), an exact card, or any
## card of a suit. Exactly one of rank / card / suit_any is used.

## Any card of this rank (any suit). 0 = not a rank ingredient.
@export_range(0, 13) var rank: int = 0
## An exact card (used for the T2 inside a T3 recipe).
@export var card: CardData
## Any non-ace card of `suit`.
@export var suit_any: bool = false
@export var suit: CardData.Suit = CardData.Suit.HEARTS


func matches(candidate: CardData) -> bool:
	if candidate == null or candidate.joker or candidate.is_ace():
		return false
	if card != null:
		return candidate.same_card(card)
	if rank > 0:
		return candidate.rank == rank
	if suit_any:
		return candidate.suit == suit
	return false


func is_exact() -> bool:
	return card != null


func describe() -> String:
	if card != null:
		return card.label()
	if rank > 0:
		return "a %s" % CardData.rank_text(rank)
	return "any %s" % CardData.SUIT_GLYPHS[suit]
