class_name CardLibrary
extends Resource
## Every card that exists, for lookups (e.g. "the card one rank higher").

@export var cards: Array[CardData] = []


func find(suit: CardData.Suit, rank: int) -> CardData:
	for card: CardData in cards:
		if card.suit == suit and card.rank == rank:
			return card
	return null


func cards_of_tier(tier: int) -> Array[CardData]:
	var found: Array[CardData] = []
	for card: CardData in cards:
		if card.tier() == tier:
			found.append(card)
	return found
