extends "res://tests/framework/test_case.gd"

const CardDataScript := preload("res://items/card_data.gd")
const CardStackScript := preload("res://items/card_stack.gd")


func _card(suit: int, rank: int) -> CardData:
	var card: CardData = CardDataScript.new()
	card.suit = suit as CardData.Suit
	card.rank = rank
	return card


func _recipe(ingredients: Array[RecipeIngredient]) -> RecipeData:
	var recipe: RecipeData = RecipeData.new()
	recipe.result = _card(0, 7)
	recipe.ingredients = ingredients
	recipe.gold_units = 8.0
	recipe.requires_suit = false
	return recipe


func _exact(card: CardData) -> RecipeIngredient:
	var ingredient: RecipeIngredient = RecipeIngredient.new()
	ingredient.card = card
	return ingredient


func _any(suit: int) -> RecipeIngredient:
	var ingredient: RecipeIngredient = RecipeIngredient.new()
	ingredient.suit_any = true
	ingredient.suit = suit as CardData.Suit
	return ingredient


func _rank(rank: int) -> RecipeIngredient:
	var ingredient: RecipeIngredient = RecipeIngredient.new()
	ingredient.rank = rank
	return ingredient


func _joker() -> CardData:
	var card: CardData = CardDataScript.new()
	card.joker = true
	return card


func _stacks(cards: Array[CardData]) -> Array[CardStack]:
	var stacks: Array[CardStack] = []
	stacks.resize(5)
	for i: int in cards.size():
		stacks[i] = CardStackScript.new(cards[i]) if cards[i] != null else null
	return stacks


func test_recipe_complete_with_exact_and_suit_ingredients() -> void:
	var three_h: CardData = _card(0, 3)
	var ingredients: Array[RecipeIngredient] = [_exact(three_h), _any(3)]
	var held: Array[CardData] = [_card(3, 5), null, _card(0, 3)]
	var plan: RecipePlan = RecipePlan.build(_recipe(ingredients), _stacks(held), false)
	assert_true(plan.is_complete())
	assert_eq(plan.assignment, [2, 0])
	assert_eq(plan.jokers_used, 0)


func test_recipe_missing_ingredient() -> void:
	var ingredients: Array[RecipeIngredient] = [_exact(_card(0, 3)), _any(3)]
	var held: Array[CardData] = [_card(0, 3)]
	var plan: RecipePlan = RecipePlan.build(_recipe(ingredients), _stacks(held), false)
	assert_false(plan.is_complete())
	assert_eq(plan.missing, 1)


func test_joker_fills_gap_and_costs_more() -> void:
	var ingredients: Array[RecipeIngredient] = [_exact(_card(0, 3)), _any(3)]
	var held: Array[CardData] = [_card(0, 3), _joker()]
	var plan: RecipePlan = RecipePlan.build(_recipe(ingredients), _stacks(held), false)
	assert_true(plan.is_complete())
	assert_eq(plan.jokers_used, 1)
	var economy: GoldEconomy = GoldEconomy.new()
	economy.base_unit = 5
	economy.joker_surcharge = 0.5
	assert_eq(plan.cost(economy, 0.0), 60)
	assert_eq(plan.cost(economy, 10.0), 50)


func test_wildcard_only_when_allowed_and_once() -> void:
	var ingredients: Array[RecipeIngredient] = [_exact(_card(0, 3)), _exact(_card(1, 4))]
	var held: Array[CardData] = [_card(2, 6), _card(3, 2)]
	var without: RecipePlan = RecipePlan.build(_recipe(ingredients), _stacks(held), false)
	assert_eq(without.missing, 2)
	var with_wild: RecipePlan = RecipePlan.build(_recipe(ingredients), _stacks(held), true)
	assert_eq(with_wild.missing, 1)
	assert_ne(with_wild.wildcard_slot, -1)


func test_aces_and_jokers_never_match_ingredients() -> void:
	var ingredient: RecipeIngredient = _any(0)
	assert_false(ingredient.matches(_card(0, 1)))
	assert_false(ingredient.matches(_joker()))
	assert_true(ingredient.matches(_card(0, 9)))


func test_rank_recipe_needs_one_card_of_the_suit() -> void:
	var ingredients: Array[RecipeIngredient] = [_rank(3), _rank(2)]
	var recipe: RecipeData = _recipe(ingredients)
	recipe.requires_suit = true
	recipe.required_suit = CardData.Suit.HEARTS
	var off_suit: Array[CardData] = [_card(2, 3), _card(3, 2)]
	var plan: RecipePlan = RecipePlan.build(recipe, _stacks(off_suit), false)
	assert_false(plan.is_complete())
	assert_false(plan.suit_satisfied)
	assert_eq(plan.missing, 1)
	var one_heart: Array[CardData] = [_card(2, 3), _card(0, 2)]
	plan = RecipePlan.build(recipe, _stacks(one_heart), false)
	assert_true(plan.is_complete())
	assert_eq(plan.used_slots.size(), 2)


func test_matcher_prefers_the_suited_card_when_several_fit() -> void:
	var ingredients: Array[RecipeIngredient] = [_rank(3), _rank(2)]
	var recipe: RecipeData = _recipe(ingredients)
	recipe.requires_suit = true
	recipe.required_suit = CardData.Suit.SPADES
	# Two 3s: only the second is a spade. The plan must pick it.
	var held: Array[CardData] = [_card(0, 3), _card(3, 3), _card(1, 2)]
	var plan: RecipePlan = RecipePlan.build(recipe, _stacks(held), false)
	assert_true(plan.is_complete())
	assert_eq(plan.assignment[0], 1)


func test_joker_can_cover_the_suit_requirement() -> void:
	var ingredients: Array[RecipeIngredient] = [_rank(3), _rank(2)]
	var recipe: RecipeData = _recipe(ingredients)
	recipe.requires_suit = true
	recipe.required_suit = CardData.Suit.HEARTS
	var held: Array[CardData] = [_card(2, 3), _joker()]
	var plan: RecipePlan = RecipePlan.build(recipe, _stacks(held), false)
	assert_true(plan.is_complete())
	assert_eq(plan.jokers_used, 1)
