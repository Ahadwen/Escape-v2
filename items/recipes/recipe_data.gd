class_name RecipeData
extends Resource
## A fixed, learnable recipe for a T2 or T3 card.

@export var result: CardData
@export var ingredients: Array[RecipeIngredient] = []
## Price in economy base units (see GoldEconomy).
@export var gold_units: float = 8.0


func describe_ingredients() -> String:
	var parts: PackedStringArray = PackedStringArray()
	for ingredient: RecipeIngredient in ingredients:
		parts.append(ingredient.describe())
	return " + ".join(parts)
