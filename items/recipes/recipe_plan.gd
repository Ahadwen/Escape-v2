class_name RecipePlan
extends RefCounted
## How a recipe would be paid for from the player's cards: which slots are
## used, how many jokers, whether the Forger wildcard is used, what's missing.
## Built by RecipePlan.build (pure, unit-tested), which tries every way of
## assigning cards to ingredients and keeps the best: fewest missing, then
## fewest jokers, then no wildcard. A missing suit requirement counts as one
## missing card.

const JOKER: int = -2
const WILDCARD: int = -3
const MISSING: int = -1

var recipe: RecipeData
## Inventory slots consumed (matching cards, jokers and the wildcard card).
var used_slots: Array[int] = []
## Per ingredient: the slot paying for it, or -1 if missing.
var assignment: Array[int] = []
var jokers_used: int = 0
## Slot used as a free wildcard (Q♦ Forger), or -1.
var wildcard_slot: int = -1
## Missing ingredients (+1 if the suit requirement isn't met).
var missing: int = 0
var suit_satisfied: bool = true


func is_complete() -> bool:
	return missing == 0


## Gold cost given the economy and the player's recipe discount.
func cost(economy: GoldEconomy, discount: float) -> int:
	var base: float = economy.units(recipe.gold_units)
	base *= 1.0 + economy.joker_surcharge * jokers_used
	return maxi(roundi(base - discount), 0)


## Fraction of ingredients the player holds outright (for weighting).
func progress() -> float:
	if recipe.ingredients.is_empty():
		return 1.0
	var held: int = recipe.ingredients.size() - missing - jokers_used
	held -= 1 if wildcard_slot != -1 else 0
	return clampf(float(held) / recipe.ingredients.size(), 0.0, 1.0)


static func build(
	p_recipe: RecipeData, stacks: Array[CardStack], allow_wildcard: bool
) -> RecipePlan:
	var jokers: Array[int] = []
	for slot: int in stacks.size():
		if stacks[slot] != null and stacks[slot].card.joker:
			jokers.append(slot)
	var best: Array = [null, INF]  # [choices, score]
	var choices: Array[int] = []
	choices.resize(p_recipe.ingredients.size())
	_search(p_recipe, stacks, jokers, allow_wildcard, 0, choices, [], best)
	return _make_plan(p_recipe, stacks, jokers, best[0])


## Depth-first over ingredients. Each one can take a matching unused card, a
## joker, the wildcard (any unused normal card), or be missing.
static func _search(
	recipe: RecipeData,
	stacks: Array[CardStack],
	jokers: Array[int],
	allow_wildcard: bool,
	index: int,
	choices: Array[int],
	used: Array,
	best: Array
) -> void:
	if index == choices.size():
		var score: float = _score(recipe, stacks, choices)
		if score < best[1]:
			best[0] = choices.duplicate()
			best[1] = score
		return
	var ingredient: RecipeIngredient = recipe.ingredients[index]
	for slot: int in stacks.size():
		if slot in used or stacks[slot] == null or not ingredient.matches(stacks[slot].card):
			continue
		choices[index] = slot
		_search(recipe, stacks, jokers, allow_wildcard, index + 1, choices, used + [slot], best)
	for joker_slot: int in jokers:
		if joker_slot in used:
			continue
		choices[index] = JOKER
		_search(
			recipe, stacks, jokers, allow_wildcard, index + 1, choices, used + [joker_slot], best
		)
		break
	if allow_wildcard and not WILDCARD in choices.slice(0, index):
		choices[index] = WILDCARD
		_search(recipe, stacks, jokers, allow_wildcard, index + 1, choices, used, best)
	choices[index] = MISSING
	_search(recipe, stacks, jokers, allow_wildcard, index + 1, choices, used, best)


## Lower is better: missing dominates, then jokers, then the wildcard.
static func _score(recipe: RecipeData, stacks: Array[CardStack], choices: Array[int]) -> float:
	var missing_count: int = choices.count(MISSING)
	if not _suit_ok(recipe, stacks, choices):
		missing_count += 1
	return missing_count * 100.0 + choices.count(JOKER) * 10.0 + choices.count(WILDCARD)


static func _suit_ok(recipe: RecipeData, stacks: Array[CardStack], choices: Array[int]) -> bool:
	if not recipe.requires_suit:
		return true
	for choice: int in choices:
		if choice == JOKER or choice == WILDCARD:
			return true
		if choice >= 0 and stacks[choice].card.suit == recipe.required_suit:
			return true
	return false


static func _make_plan(
	recipe: RecipeData, stacks: Array[CardStack], jokers: Array[int], choices: Array
) -> RecipePlan:
	var plan: RecipePlan = RecipePlan.new()
	plan.recipe = recipe
	var picks: Array[int] = []
	for c: int in choices:
		picks.append(c)
	var taken: Array[int] = []
	for c: int in picks:
		if c >= 0:
			taken.append(c)
	var free_jokers: Array[int] = []
	for j: int in jokers:
		if not j in taken:
			free_jokers.append(j)
	for c: int in picks:
		match c:
			JOKER:
				var joker_slot: int = free_jokers.pop_front()
				plan.assignment.append(joker_slot)
				plan.jokers_used += 1
			WILDCARD:
				var wild: int = _wildcard_slot(stacks, taken)
				plan.wildcard_slot = wild
				plan.assignment.append(wild)
				if wild != -1:
					taken.append(wild)
			_:
				plan.assignment.append(c)
	for slot: int in plan.assignment:
		if slot < 0:
			plan.missing += 1
		elif not slot in plan.used_slots:
			plan.used_slots.append(slot)
	plan.suit_satisfied = _suit_ok(recipe, stacks, picks)
	if not plan.suit_satisfied:
		plan.missing += 1
	return plan


static func _wildcard_slot(stacks: Array[CardStack], taken: Array[int]) -> int:
	for slot: int in stacks.size():
		var stack: CardStack = stacks[slot]
		if slot in taken or stack == null or stack.card.joker or stack.card.is_ace():
			continue
		return slot
	return -1
