class_name ForgeScreen
extends Control
## The safehouse forge (the game is paused). Shows a few recipes, what you
## have for each, and the price. Craft consumes the ingredients and puts the
## result in a freed slot. Reroll for gold (free rerolls first). Leave ends
## the visit.

signal left

const BASE_OFFERS: int = 3

@export var recipe_book: RecipeBook
@export var economy: GoldEconomy

var _player: Player
var _offers: Array[RecipeData] = []
var _free_rerolls: int = 0
var _wildcard_available: bool = false

var _title: Label
var _gold: Label
var _cards_row: HBoxContainer
var _offers_box: VBoxContainer
var _reroll_button: Button
var _leave_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.02, 0.04, 0.08, 0.85)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	center.add_child(column)
	_title = Label.new()
	_title.text = "Safehouse — the forge"
	_title.add_theme_font_size_override("font_size", 28)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	_gold = Label.new()
	_gold.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	column.add_child(_gold)
	_cards_row = HBoxContainer.new()
	_cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_row.add_theme_constant_override("separation", 8)
	column.add_child(_cards_row)
	_offers_box = VBoxContainer.new()
	_offers_box.add_theme_constant_override("separation", 8)
	column.add_child(_offers_box)
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	column.add_child(buttons)
	_reroll_button = Button.new()
	_reroll_button.custom_minimum_size = Vector2(180, 44)
	_reroll_button.pressed.connect(_on_reroll)
	buttons.add_child(_reroll_button)
	_leave_button = Button.new()
	_leave_button.text = "Leave"
	_leave_button.custom_minimum_size = Vector2(180, 44)
	_leave_button.pressed.connect(_on_leave)
	buttons.add_child(_leave_button)


func open(player: Player) -> void:
	_player = player
	_free_rerolls = roundi(player.stats.get_value(StatIds.FREE_REROLLS))
	_wildcard_available = player.stats.get_value(StatIds.FORGE_WILDCARDS) >= 1.0
	visible = true
	var pause: PauseController = PauseController.find(get_tree())
	if pause != null:
		pause.push_menu_pause()
	_roll_offers()
	_leave_button.grab_focus()


func _offer_count() -> int:
	return BASE_OFFERS + roundi(_player.stats.get_value(StatIds.EXTRA_RECIPE_OFFERS))


func _roll_offers() -> void:
	if recipe_book == null:
		_offers.clear()
	else:
		_offers = recipe_book.pick_offers(_offer_count(), _player.cards.slots, _wildcard_available)
	_rebuild()


func _rebuild() -> void:
	_gold.text = "%d gold" % _player.wallet.gold
	for child: Node in _cards_row.get_children():
		child.queue_free()
	for i: int in CardInventory.SLOT_COUNT:
		var view: CardView = CardView.new()
		view.focus_mode = Control.FOCUS_NONE
		view.disabled = true
		view.empty_text = "Slot %d\nempty" % (i + 1)
		_cards_row.add_child(view)
		view.stack = _player.cards.stack_at(i)
	for child: Node in _offers_box.get_children():
		child.queue_free()
	if _offers.is_empty():
		var none: Label = Label.new()
		none.text = "No recipes on offer."
		none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_offers_box.add_child(none)
	for recipe: RecipeData in _offers:
		_offers_box.add_child(_offer_row(recipe))
	var reroll_cost: int = economy.units(economy.reroll) if economy != null else 0
	if _free_rerolls > 0:
		_reroll_button.text = "Reroll (free ×%d)" % _free_rerolls
		_reroll_button.disabled = false
	else:
		_reroll_button.text = "Reroll (%d g)" % reroll_cost
		_reroll_button.disabled = not _player.wallet.can_afford(reroll_cost)


func _offer_row(recipe: RecipeData) -> Control:
	var plan: RecipePlan = RecipePlan.build(recipe, _player.cards.slots, _wildcard_available)
	var discount: float = _player.stats.get_value(StatIds.RECIPE_DISCOUNT)
	var cost: int = plan.cost(economy, discount)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var result: CardView = CardView.new()
	result.focus_mode = Control.FOCUS_NONE
	result.disabled = true
	row.add_child(result)
	result.stack = CardStack.new(recipe.result)
	var details: VBoxContainer = VBoxContainer.new()
	details.custom_minimum_size = Vector2(340, 0)
	details.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(details)
	var needs: Label = Label.new()
	needs.text = "Needs: " + _ingredient_status(plan)
	needs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(needs)
	var extras: PackedStringArray = PackedStringArray()
	if plan.jokers_used > 0:
		extras.append(
			(
				"uses %d joker(s), +%d%% gold"
				% [plan.jokers_used, roundi(plan.jokers_used * economy.joker_surcharge * 100.0)]
			)
		)
	if plan.wildcard_slot != -1:
		extras.append("uses your Forger wildcard")
	if not extras.is_empty():
		var extra_label: Label = Label.new()
		extra_label.text = ", ".join(extras)
		details.add_child(extra_label)
	var craft: Button = Button.new()
	craft.text = "Craft — %d g" % cost
	craft.custom_minimum_size = Vector2(160, 40)
	craft.disabled = not plan.is_complete() or not _player.wallet.can_afford(cost)
	craft.pressed.connect(_on_craft.bind(recipe))
	details.add_child(craft)
	return row


func _ingredient_status(plan: RecipePlan) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for i: int in plan.recipe.ingredients.size():
		var ingredient: RecipeIngredient = plan.recipe.ingredients[i]
		var slot: int = plan.assignment[i]
		var mark: String = "✗"
		if slot != -1:
			var stack: CardStack = _player.cards.stack_at(slot)
			mark = "✓" if ingredient.matches(stack.card) else "(%s)" % stack.card.label()
		parts.append("%s %s" % [ingredient.describe(), mark])
	return ", ".join(parts)


func _on_craft(recipe: RecipeData) -> void:
	var plan: RecipePlan = RecipePlan.build(recipe, _player.cards.slots, _wildcard_available)
	var cost: int = plan.cost(economy, _player.stats.get_value(StatIds.RECIPE_DISCOUNT))
	if not plan.is_complete() or not _player.wallet.spend(cost):
		return
	var stacks: Array[CardStack] = _player.cards.slots.duplicate()
	var into: int = plan.used_slots.min()
	for slot: int in plan.used_slots:
		stacks[slot] = null
	stacks[into] = CardStack.new(recipe.result)
	_player.cards.replace_all(stacks)
	if plan.wildcard_slot != -1:
		_wildcard_available = false
	_offers.erase(recipe)
	_title.text = "Forged %s" % recipe.result.label()
	_rebuild()


func _on_reroll() -> void:
	if _free_rerolls > 0:
		_free_rerolls -= 1
	elif not _player.wallet.spend(economy.units(economy.reroll)):
		return
	_roll_offers()


func _on_leave() -> void:
	visible = false
	var pause: PauseController = PauseController.find(get_tree())
	if pause != null:
		pause.pop_menu_pause()
	left.emit()
