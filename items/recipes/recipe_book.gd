class_name RecipeBook
extends Resource
## Every recipe, and how the safehouse picks which to offer.

@export var recipes: Array[RecipeData] = []
## Offer weight = 1 + progress_weight * (fraction of ingredients held).
@export var progress_weight: float = 4.0


## Picks `count` different recipes, weighted towards ones the player is close
## to completing. Excludes results the player already holds.
func pick_offers(
	count: int, stacks: Array[CardStack], allow_wildcard: bool, exclude: Array[RecipeData] = []
) -> Array[RecipeData]:
	var pool: Array[RecipeData] = []
	var weights: Array[float] = []
	for recipe: RecipeData in recipes:
		if recipe in exclude or _holds(stacks, recipe.result):
			continue
		pool.append(recipe)
		var plan: RecipePlan = RecipePlan.build(recipe, stacks, allow_wildcard)
		weights.append(1.0 + progress_weight * plan.progress())
	var picked: Array[RecipeData] = []
	while picked.size() < count and not pool.is_empty():
		var total: float = 0.0
		for w: float in weights:
			total += w
		var roll: float = randf() * total
		var index: int = pool.size() - 1
		for i: int in pool.size():
			roll -= weights[i]
			if roll < 0.0:
				index = i
				break
		picked.append(pool[index])
		pool.remove_at(index)
		weights.remove_at(index)
	return picked


static func _holds(stacks: Array[CardStack], card: CardData) -> bool:
	for stack: CardStack in stacks:
		if stack != null and stack.card.same_card(card):
			return true
	return false
