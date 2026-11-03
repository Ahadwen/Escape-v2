class_name CardData
extends Resource
## A card: suit (family) and rank (tier and strength). T1 (2–6) is stats,
## T2 (7–10) and T3 (J, Q, K) add effects, Aces are consumables.

enum Suit { HEARTS, DIAMONDS, CLUBS, SPADES }

const ACE: int = 1
const JACK: int = 11
const QUEEN: int = 12
const KING: int = 13
const SUIT_GLYPHS: Array[String] = ["♥", "♦", "♣", "♠"]
const SUIT_NAMES: Array[String] = ["Hearts", "Diamonds", "Clubs", "Spades"]
const SUIT_COLORS: Array[Color] = [
	Color(0.9, 0.3, 0.35), Color(0.95, 0.65, 0.25), Color(0.45, 0.75, 0.45), Color(0.55, 0.65, 0.95)
]

@export var suit: Suit = Suit.HEARTS
@export_range(1, 13) var rank: int = 2
## Optional name for effect cards (stat cards are just "4♥").
@export var title: String = ""
## Effect text shown under the stats.
@export_multiline var description: String = ""
@export var stats: Array[CardStat] = []
## Aces only: what using one does.
@export var ace_effect: AceEffect
## T2/T3: what the card does beyond its stats.
@export var effect: CardEffect
## Jokers: no suit or stats; stand in for one recipe ingredient (for more gold).
@export var joker: bool = false


static func rank_text(value: int) -> String:
	match value:
		ACE:
			return "A"
		JACK:
			return "J"
		QUEEN:
			return "Q"
		KING:
			return "K"
	return str(value)


func label() -> String:
	if joker:
		return "Joker"
	return "%s%s" % [rank_text(rank), SUIT_GLYPHS[suit]]


func is_ace() -> bool:
	return rank == ACE and not joker


## Same card identity (suit and rank), even across different resource copies.
func same_card(other: CardData) -> bool:
	return other != null and other.joker == joker and other.suit == suit and other.rank == rank


## -1 = joker, 0 = ace, 1 = 2–6, 2 = 7–10, 3 = J–K.
func tier() -> int:
	if joker:
		return -1
	if rank == ACE:
		return 0
	if rank <= 6:
		return 1
	if rank <= 10:
		return 2
	return 3


func color() -> Color:
	return Color(0.75, 0.5, 0.95) if joker else SUIT_COLORS[suit]


func stat_lines() -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	for line: CardStat in stats:
		lines.append(line.describe())
	return lines
