class_name LootTable
extends Resource
## What chests drop: any card from Ace to 10. Mostly low ranks; T2s (7-10)
## are rarer, and Aces and jokers have their own chances. (J/Q/K come from
## safehouse recipes only.)

const REROLLS: int = 12

@export var library: CardLibrary
@export_range(0.0, 1.0) var ace_chance: float = 0.15
@export_range(0.0, 1.0) var joker_chance: float = 0.05
## Relative weight of each rank, index 0 = rank 2 ... index 8 = rank 10.
@export var rank_weights: PackedFloat32Array = PackedFloat32Array(
	[5.0, 4.0, 3.0, 2.0, 1.0, 1.2, 1.0, 0.8, 0.6]
)


## A random drop. `is_held(card) -> bool` (optional) excludes cards already
## held; it re-rolls a few times, then gives up on the exclusion.
func roll(is_held: Callable = Callable()) -> CardData:
	for attempt: int in REROLLS:
		var card: CardData = _roll_once()
		if card == null or not is_held.is_valid() or not is_held.call(card) or card.joker:
			return card
	return _roll_once()


func _roll_once() -> CardData:
	if library == null:
		return null
	if randf() < joker_chance and library.joker() != null:
		return library.joker()
	if randf() < ace_chance:
		var aces: Array[CardData] = library.cards_of_tier(0)
		if not aces.is_empty():
			return aces.pick_random()
	var rank: int = 2 + _pick_weighted(rank_weights)
	var suit: CardData.Suit = (randi() % 4) as CardData.Suit
	return library.find(suit, rank)


static func _pick_weighted(weights: PackedFloat32Array) -> int:
	var total: float = 0.0
	for w: float in weights:
		total += w
	var roll_value: float = randf() * total
	for i: int in weights.size():
		roll_value -= weights[i]
		if roll_value < 0.0:
			return i
	return weights.size() - 1
