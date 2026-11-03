class_name RecipeData
extends Resource
## A fixed, learnable recipe for a T2 or T3 card: ingredients (mostly ranks,
## any suit) and, usually, a suit requirement: at least one ingredient card
## must be of `required_suit` (a joker or wildcard can stand in for it).

@export var result: CardData
@export var ingredients: Array[RecipeIngredient] = []
@export var requires_suit: bool = true
@export var required_suit: CardData.Suit = CardData.Suit.HEARTS
## Price in economy base units (see GoldEconomy).
@export var gold_units: float = 8.0


func describe_ingredients() -> String:
	var parts: PackedStringArray = PackedStringArray()
	for ingredient: RecipeIngredient in ingredients:
		parts.append(ingredient.describe())
	var text: String = " + ".join(parts)
	if requires_suit:
		text += " (one %s)" % CardData.SUIT_GLYPHS[required_suit]
	return text
