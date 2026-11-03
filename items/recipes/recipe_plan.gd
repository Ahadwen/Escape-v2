class_name RecipePlan
extends RefCounted
## How a recipe would be paid for from the player's cards: which slots are
## used, how many jokers, whether the Forger wildcard is used, what's missing.
## Built by RecipePlan.build (pure, unit-tested).

var recipe: RecipeData
## Inventory slots consumed (matching cards, jokers and the wildcard card).
var used_slots: Array[int] = []
## Per ingredient: the slot paying for it, or -1 if missing.
var assignment: Array[int] = []
var jokers_used: int = 0
## Slot used as a free wildcard (Q♦ Forger), or -1.
var wildcard_slot: int = -1
var missing: int = 0


func is_complete() -> bool:
	return missing == 0


## Gold cost given the economy and the player's recipe discount.
func cost(economy: GoldEconomy, discount: float) -> int:
	var base: float = economy.units(recipe.gold_units)
	base *= 1.0 + economy.joker_surcharge * jokers_used
	return maxi(roundi(base - discount), 0)


## Fraction of ingredients the player holds outright (for offer weighting).
func progress() -> float:
	if recipe.ingredients.is_empty():
		return 1.0
	var held: int = recipe.ingredients.size() - missing - jokers_used
	held -= 1 if wildcard_slot != -1 else 0
	return clampf(float(held) / recipe.ingredients.size(), 0.0, 1.0)


## Matches exact ingredients first, then suit ingredients, then fills gaps
## with jokers, then (if allowed) one wildcard card.
static func build(
	p_recipe: RecipeData, stacks: Array[CardStack], allow_wildcard: bool
) -> RecipePlan:
	var plan: RecipePlan = RecipePlan.new()
	plan.recipe = p_recipe
	var count: int = p_recipe.ingredients.size()
	plan.assignment.resize(count)
	plan.assignment.fill(-1)
	var taken: Array[bool] = []
	taken.resize(stacks.size())
	taken.fill(false)
	for exact_pass: bool in [true, false]:
		for i: int in count:
			var ingredient: RecipeIngredient = p_recipe.ingredients[i]
			if plan.assignment[i] != -1 or ingredient.is_exact() != exact_pass:
				continue
			for slot: int in stacks.size():
				if taken[slot] or stacks[slot] == null:
					continue
				if ingredient.matches(stacks[slot].card):
					plan.assignment[i] = slot
					taken[slot] = true
					break
	for i: int in count:
		if plan.assignment[i] != -1:
			continue
		var filler: int = _find(stacks, taken, func(c: CardData) -> bool: return c.joker)
		if filler != -1:
			plan.jokers_used += 1
		elif allow_wildcard and plan.wildcard_slot == -1:
			filler = _find(
				stacks, taken, func(c: CardData) -> bool: return not c.joker and not c.is_ace()
			)
			plan.wildcard_slot = filler
		if filler == -1:
			plan.missing += 1
			continue
		plan.assignment[i] = filler
		taken[filler] = true
	for slot: int in plan.assignment:
		if slot != -1:
			plan.used_slots.append(slot)
	return plan


static func _find(stacks: Array[CardStack], taken: Array[bool], accept: Callable) -> int:
	for slot: int in stacks.size():
		if not taken[slot] and stacks[slot] != null and accept.call(stacks[slot].card):
			return slot
	return -1
