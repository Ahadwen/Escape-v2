class_name ShopScreen
extends Control
## The safehouse shop (the game is paused). A grid of everything the recipe
## book can make: items you can make right now with your cards are outlined
## in gold, ones a card short faintly, the rest dimmed. Clicking an item opens
## its details page: the card, what it does, the recipe (what you have and
## what's missing, jokers and the Q♦ Forger wildcard can stand in), the price
## and Buy. Buying trades in the ingredients and gold; the result goes into a
## freed slot.

signal closed

enum Status { READY, NEAR, LOCKED, OWNED }

const COLUMNS: int = 6
const TILE_SIZE: Vector2 = Vector2(112, 86)
const OUTLINE_READY: Color = Color(1.0, 0.82, 0.3)
const OUTLINE_NEAR: Color = Color(1.0, 0.82, 0.3, 0.35)

@export var recipe_book: RecipeBook
@export var economy: GoldEconomy

var _player: Player
var _wildcard_available: bool = false
var _title: Label
var _gold: Label
var _cards_row: HBoxContainer
var _grid_page: VBoxContainer
var _grid: GridContainer
var _details_page: VBoxContainer
var _close_button: Button
var _selected: RecipeData


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.02, 0.04, 0.08, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var center: CenterContainer = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	center.add_child(column)
	_title = _label("", 28)
	column.add_child(_title)
	_gold = _label("", 16)
	_gold.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	column.add_child(_gold)
	_cards_row = HBoxContainer.new()
	_cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_row.add_theme_constant_override("separation", 8)
	column.add_child(_cards_row)
	_build_grid_page(column)
	_details_page = VBoxContainer.new()
	_details_page.add_theme_constant_override("separation", 10)
	_details_page.visible = false
	column.add_child(_details_page)


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
	_show_grid()


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
	if not visible or not event.is_action_pressed(&"ui_cancel"):
		return
	if _details_page.visible:
		_show_grid()
	else:
		close()
	get_viewport().set_input_as_handled()


## How an item stands for the player right now.
func status_of(recipe: RecipeData) -> Status:
	if RecipeBook.holds_card(_player.cards.slots, recipe.result):
		return Status.OWNED
	var plan: RecipePlan = RecipePlan.build(recipe, _player.cards.slots, _wildcard_available)
	if plan.is_complete():
		return Status.READY
	return Status.NEAR if plan.missing == 1 else Status.LOCKED


# --- Grid page ----------------------------------------------------------------


func _build_grid_page(column: VBoxContainer) -> void:
	_grid_page = VBoxContainer.new()
	_grid_page.add_theme_constant_override("separation", 12)
	column.add_child(_grid_page)
	var legend: Label = _label("Gold outline: you can make it now. Faint: one card short.", 13)
	legend.modulate = Color(1, 1, 1, 0.7)
	_grid_page.add_child(legend)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	_grid_page.add_child(_grid)
	_close_button = Button.new()
	_close_button.text = "Close"
	_close_button.custom_minimum_size = Vector2(180, 44)
	_close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_close_button.pressed.connect(close)
	_grid_page.add_child(_close_button)


func _show_grid() -> void:
	_details_page.visible = false
	_grid_page.visible = true
	_refresh_header()
	for child: Node in _grid.get_children():
		child.queue_free()
	var first: Button = null
	if recipe_book != null:
		for recipe: RecipeData in recipe_book.recipes:
			var tile: Button = _tile(recipe, status_of(recipe))
			_grid.add_child(tile)
			if first == null or (_selected != null and recipe == _selected):
				first = tile
	if first != null:
		first.grab_focus.call_deferred()
	else:
		_close_button.grab_focus()


func _tile(recipe: RecipeData, status: Status) -> Button:
	var card: CardData = recipe.result
	var tile: Button = Button.new()
	tile.custom_minimum_size = TILE_SIZE
	tile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tile.text = card.label() if card.title.is_empty() else "%s\n%s" % [card.label(), card.title]
	if status == Status.OWNED:
		tile.text += "\n(owned)"
	tile.add_theme_font_size_override("font_size", 13)
	var outline: Color = Color(0, 0, 0, 0)
	match status:
		Status.READY:
			outline = OUTLINE_READY
		Status.NEAR:
			outline = OUTLINE_NEAR
	var base: Color = card.color().darkened(0.55)
	tile.add_theme_stylebox_override("normal", _tile_style(base, outline, 3))
	tile.add_theme_stylebox_override("hover", _tile_style(base.lightened(0.15), outline, 3))
	tile.add_theme_stylebox_override("pressed", _tile_style(base.lightened(0.25), outline, 3))
	tile.add_theme_stylebox_override("focus", _tile_style(Color(0, 0, 0, 0), Color.WHITE, 2))
	if status == Status.LOCKED or status == Status.OWNED:
		tile.modulate = Color(1, 1, 1, 0.45)
	tile.pressed.connect(_show_details.bind(recipe))
	return tile


func _tile_style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width if border.a > 0.0 else 0)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(6)
	return style


# --- Details page -------------------------------------------------------------


func _show_details(recipe: RecipeData) -> void:
	_selected = recipe
	_grid_page.visible = false
	_details_page.visible = true
	for child: Node in _details_page.get_children():
		child.queue_free()
	var plan: RecipePlan = RecipePlan.build(recipe, _player.cards.slots, _wildcard_available)
	var status: Status = status_of(recipe)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_details_page.add_child(row)
	var view: CardView = CardView.new()
	view.focus_mode = Control.FOCUS_NONE
	view.disabled = true
	row.add_child(view)
	_readable(view)
	view.stack = CardStack.new(recipe.result)
	var info: VBoxContainer = VBoxContainer.new()
	info.custom_minimum_size = Vector2(380, 0)
	info.add_theme_constant_override("separation", 6)
	row.add_child(info)
	info.add_child(_left_label("Recipe", 18))
	for line: String in _ingredient_lines(plan):
		info.add_child(_left_label(line, 15))
	for note: String in _plan_notes(plan):
		info.add_child(_left_label(note, 13))
	_add_actions(info, recipe, plan, status)


func _add_actions(
	info: VBoxContainer, recipe: RecipeData, plan: RecipePlan, status: Status
) -> void:
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	info.add_child(buttons)
	var back: Button = Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(110, 40)
	back.pressed.connect(_show_grid)
	var buy: Button = Button.new()
	buy.custom_minimum_size = Vector2(170, 40)
	var cost: int = plan.cost(economy, _player.stats.get_value(StatIds.RECIPE_DISCOUNT))
	match status:
		Status.OWNED:
			buy.text = "Already held"
			buy.disabled = true
		Status.READY:
			buy.text = "Buy — %d g" % cost
			buy.disabled = not _player.wallet.can_afford(cost)
			if buy.disabled:
				buy.text = "Need %d g" % cost
		_:
			buy.text = "Missing cards"
			buy.disabled = true
	buy.pressed.connect(_on_buy.bind(recipe))
	buttons.add_child(buy)
	buttons.add_child(back)
	(back if buy.disabled else buy).grab_focus.call_deferred()


## One line per ingredient: ✓ and the card filling it, or ✗ missing.
func _ingredient_lines(plan: RecipePlan) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	for i: int in plan.recipe.ingredients.size():
		var ingredient: RecipeIngredient = plan.recipe.ingredients[i]
		var slot: int = plan.assignment[i]
		var mark: String = "✗ missing"
		if slot != -1:
			var stack: CardStack = _player.cards.stack_at(slot)
			mark = "✓ %s" % stack.card.label()
		lines.append("%s   %s" % [ingredient.describe(), mark])
	if plan.recipe.requires_suit:
		var glyph: String = CardData.SUIT_GLYPHS[plan.recipe.required_suit]
		lines.append("one %s among them   %s" % [glyph, "✓" if plan.suit_satisfied else "✗"])
	return lines


func _plan_notes(plan: RecipePlan) -> PackedStringArray:
	var notes: PackedStringArray = PackedStringArray()
	if plan.jokers_used > 0:
		var surcharge: int = roundi(plan.jokers_used * economy.joker_surcharge * 100.0)
		notes.append("Uses %d joker(s): +%d%% gold" % [plan.jokers_used, surcharge])
	if plan.wildcard_slot != -1:
		notes.append("Uses your Forger wildcard")
	notes.append("The ingredients are traded in.")
	return notes


# --- Shared -------------------------------------------------------------------


func _refresh_header() -> void:
	_gold.text = "%d gold" % _player.wallet.gold
	for child: Node in _cards_row.get_children():
		child.queue_free()
	var views: Array[Control] = DeckLayout.build(_cards_row, _header_view, 4)
	for i: int in views.size():
		(views[i] as CardView).stack = _player.cards.stack_at(i)


## A small, display-only view of one deck slot for the header.
func _header_view(slot: int) -> Control:
	var view: CardView = CardView.new()
	view.compact = true
	view.view_size = Vector2(78, 46)
	if slot == CardInventory.ACE_SLOT:
		view.view_size = Vector2(78, 96)
	elif CardInventory.is_backpack(slot):
		view.view_size = Vector2(96, 28)
	view.focus_mode = Control.FOCUS_NONE
	view.disabled = true
	view.empty_text = CardInventory.slot_label(slot)
	_readable(view)
	return view


## Display-only card views are disabled buttons; keep their text bright.
func _readable(view: CardView) -> void:
	view.add_theme_color_override("font_disabled_color", Color.WHITE)


func _label(text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _left_label(text: String, font_size: int) -> Label:
	var label: Label = _label(text, font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


static func _free_backpack(stacks: Array[CardStack]) -> int:
	for i: int in range(CardInventory.RANK_SLOTS, CardInventory.SLOT_COUNT):
		if stacks[i] == null:
			return i
	return -1


func _on_buy(recipe: RecipeData) -> void:
	var plan: RecipePlan = RecipePlan.build(recipe, _player.cards.slots, _wildcard_available)
	var cost: int = plan.cost(economy, _player.stats.get_value(StatIds.RECIPE_DISCOUNT))
	if not plan.is_complete() or not _player.wallet.spend(cost):
		return
	# Trade in the ingredients; the result goes in its rank slot, and whatever
	# was there moves to the backpack.
	var stacks: Array[CardStack] = _player.cards.slots.duplicate()
	for slot: int in plan.used_slots:
		stacks[slot] = null
	var into: int = CardInventory.rank_slot(recipe.result)
	if stacks[into] != null:
		var spare: int = _free_backpack(stacks)
		if spare == -1:
			_player.wallet.add(cost)
			_title.text = "No room: free a backpack slot for your %s" % stacks[into].card.label()
			_show_grid()
			return
		stacks[spare] = stacks[into]
	stacks[into] = CardStack.new(recipe.result)
	_player.cards.replace_all(stacks)
	if plan.wildcard_slot != -1:
		_wildcard_available = false
	_title.text = "Bought %s" % recipe.result.label()
	_show_grid()
