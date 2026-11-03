class_name ShopScreen
extends Control
## The safehouse shop (the game is paused). Lists every recipe you can
## complete right now with your cards (jokers and the Q♦ Forger wildcard can
## stand in for ingredients), plus greyed-out near misses that are one
## ingredient short so you can learn recipes. Buying trades in the
## ingredients and gold; the result goes into a freed slot.

signal closed

@export var recipe_book: RecipeBook
@export var economy: GoldEconomy

var _player: Player
var _wildcard_available: bool = false
var _title: Label
var _gold: Label
var _cards_row: HBoxContainer
var _list: VBoxContainer
var _close_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.02, 0.04, 0.08, 0.85)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var center: CenterContainer = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	center.add_child(column)
	_title = Label.new()
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
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	column.add_child(_list)
	_close_button = Button.new()
	_close_button.text = "Close"
	_close_button.custom_minimum_size = Vector2(180, 44)
	_close_button.pressed.connect(close)
	column.add_child(_close_button)


## `wildcard_available`: the Q♦ Forger wildcard hasn't been used this visit.
func open(player: Player, wildcard_available: bool) -> void:
	_player = player
	_wildcard_available = (
		wildcard_available and player.stats.get_value(StatIds.FORGE_WILDCARDS) >= 1.0
	)
	_title.text = "Shop"
	visible = true
	var pause: PauseController = PauseController.find(get_tree())
	if pause != null:
		pause.push_menu_pause()
	_rebuild()
	_close_button.grab_focus()


func is_wildcard_available() -> bool:
	return _wildcard_available


func close() -> void:
	if not visible:
		return
	visible = false
	var pause: PauseController = PauseController.find(get_tree())
	if pause != null:
		pause.pop_menu_pause()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _rebuild() -> void:
	_gold.text = "%d gold" % _player.wallet.gold
	_fill_cards_row()
	for child: Node in _list.get_children():
		child.queue_free()
	var craftable: Array[RecipePlan] = []
	var near: Array[RecipePlan] = []
	if recipe_book != null:
		for recipe: RecipeData in recipe_book.recipes:
			if RecipeBook.holds_card(_player.cards.slots, recipe.result):
				continue
			var plan: RecipePlan = RecipePlan.build(
				recipe, _player.cards.slots, _wildcard_available
			)
			if plan.is_complete():
				craftable.append(plan)
			elif plan.missing == 1:
				near.append(plan)
	if craftable.is_empty() and near.is_empty():
		_add_note("Nothing you can make with these cards yet.")
	for plan: RecipePlan in craftable:
		_list.add_child(_recipe_row(plan, true))
	if not near.is_empty():
		_add_note("One card short:")
		for plan: RecipePlan in near:
			_list.add_child(_recipe_row(plan, false))


func _fill_cards_row() -> void:
	for child: Node in _cards_row.get_children():
		child.queue_free()
	for i: int in CardInventory.SLOT_COUNT:
		var view: CardView = CardView.new()
		view.focus_mode = Control.FOCUS_NONE
		view.disabled = true
		view.empty_text = "Slot %d\nempty" % (i + 1)
		_cards_row.add_child(view)
		view.stack = _player.cards.stack_at(i)


func _add_note(text: String) -> void:
	var note: Label = Label.new()
	note.text = text
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_list.add_child(note)


func _recipe_row(plan: RecipePlan, craftable: bool) -> Control:
	var cost: int = plan.cost(economy, _player.stats.get_value(StatIds.RECIPE_DISCOUNT))
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.modulate = Color.WHITE if craftable else Color(1, 1, 1, 0.5)
	var result: CardView = CardView.new()
	result.focus_mode = Control.FOCUS_NONE
	result.disabled = true
	row.add_child(result)
	result.stack = CardStack.new(plan.recipe.result)
	var details: VBoxContainer = VBoxContainer.new()
	details.custom_minimum_size = Vector2(360, 0)
	details.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(details)
	var needs: Label = Label.new()
	needs.text = "Trade in: " + _ingredient_status(plan)
	needs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(needs)
	if plan.jokers_used > 0:
		var joker_note: Label = Label.new()
		var surcharge: int = roundi(plan.jokers_used * economy.joker_surcharge * 100.0)
		joker_note.text = "Uses %d joker(s): +%d%% gold" % [plan.jokers_used, surcharge]
		details.add_child(joker_note)
	if plan.wildcard_slot != -1:
		var wild_note: Label = Label.new()
		wild_note.text = "Uses your Forger wildcard"
		details.add_child(wild_note)
	if craftable:
		var buy: Button = Button.new()
		buy.text = "Buy — %d g" % cost
		buy.custom_minimum_size = Vector2(160, 40)
		buy.disabled = not _player.wallet.can_afford(cost)
		buy.pressed.connect(_on_buy.bind(plan.recipe))
		details.add_child(buy)
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
	if plan.recipe.requires_suit:
		var suit_mark: String = "✓" if plan.suit_satisfied else "✗"
		parts.append("one %s %s" % [CardData.SUIT_GLYPHS[plan.recipe.required_suit], suit_mark])
	return ", ".join(parts)


func _on_buy(recipe: RecipeData) -> void:
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
	_title.text = "Bought %s" % recipe.result.label()
	_rebuild()
