class_name TraderScreen
extends Control
## The safehouse trader (the game is paused). Offers a few trades: give one of
## your cards, get a different card of the same or slightly higher value
## (never a T3; those are recipe-only). Reroll the offers for gold (J♦ Patron
## gives a free reroll and an extra offer).

signal closed

const BASE_OFFERS: int = 3
## A trade gives back a card worth this much more at most.
const MAX_VALUE_GAIN: int = 1
## Trades never produce cards above this rank (T3 stays recipe-only).
const MAX_RESULT_RANK: int = 10


class Offer:
	var give_slot: int
	var receive: CardData


@export var library: CardLibrary
@export var economy: GoldEconomy

var _player: Player
var _offers: Array[Offer] = []
var _free_rerolls: int = 0
var _title: Label
var _gold: Label
var _list: VBoxContainer
var _reroll_button: Button
var _close_button: Button


## Possible trade results for a card (pure, for testing).
static func candidates_for(card: CardData, cards: Array[CardData]) -> Array[CardData]:
	var found: Array[CardData] = []
	if card == null or card.value() <= 0:
		return found
	for other: CardData in cards:
		if other.joker or other.is_ace() or other.same_card(card):
			continue
		if other.rank > MAX_RESULT_RANK:
			continue
		var gain: int = other.value() - card.value()
		if gain >= 0 and gain <= MAX_VALUE_GAIN:
			found.append(other)
	return found


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.06, 0.03, 0.08, 0.85)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
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
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	column.add_child(_list)
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	column.add_child(buttons)
	_reroll_button = Button.new()
	_reroll_button.custom_minimum_size = Vector2(180, 44)
	_reroll_button.pressed.connect(_on_reroll)
	buttons.add_child(_reroll_button)
	_close_button = Button.new()
	_close_button.text = "Close"
	_close_button.custom_minimum_size = Vector2(180, 44)
	_close_button.pressed.connect(close)
	buttons.add_child(_close_button)


## Opens the trader. The first time in a visit, rolls offers; later opens in
## the same visit keep them (call reset_visit() for a new safehouse).
func open(player: Player) -> void:
	var first_open: bool = _player != player
	_player = player
	if first_open:
		_free_rerolls = roundi(player.stats.get_value(StatIds.FREE_REROLLS))
		_roll()
	_title.text = "Trader"
	visible = true
	var pause: PauseController = PauseController.find(get_tree())
	if pause != null:
		pause.push_menu_pause()
	_rebuild()
	_close_button.grab_focus()


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


func _roll() -> void:
	_offers.clear()
	if library == null:
		return
	var count: int = BASE_OFFERS + roundi(_player.stats.get_value(StatIds.EXTRA_TRADE_OFFERS))
	var tradeable: Array[int] = []
	for i: int in CardInventory.SLOT_COUNT:
		var stack: CardStack = _player.cards.stack_at(i)
		if stack != null and stack.card.value() > 0:
			tradeable.append(i)
	tradeable.shuffle()
	var attempts: int = 0
	while _offers.size() < count and not tradeable.is_empty() and attempts < 20:
		attempts += 1
		var slot: int = tradeable[attempts % tradeable.size()]
		var options: Array[CardData] = []
		for option: CardData in candidates_for(_player.cards.stack_at(slot).card, library.cards):
			# One of each card: never offer one you already hold.
			if not _player.cards.holds(option):
				options.append(option)
		if options.is_empty():
			continue
		var offer: Offer = Offer.new()
		offer.give_slot = slot
		offer.receive = options.pick_random()
		_offers.append(offer)


func _rebuild() -> void:
	_gold.text = "%d gold" % _player.wallet.gold
	for child: Node in _list.get_children():
		child.queue_free()
	if _offers.is_empty():
		var none: Label = Label.new()
		none.text = "Nothing to trade. (Bring cards rank 2–10, J, Q or K.)"
		_list.add_child(none)
	for i: int in _offers.size():
		_list.add_child(_offer_row(i, _offers[i]))
	var cost: int = economy.units(economy.reroll) if economy != null else 0
	if _free_rerolls > 0:
		_reroll_button.text = "Reroll (free ×%d)" % _free_rerolls
		_reroll_button.disabled = false
	else:
		_reroll_button.text = "Reroll (%d g)" % cost
		_reroll_button.disabled = not _player.wallet.can_afford(cost)


func _offer_row(index: int, offer: Offer) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	var give: CardView = CardView.new()
	give.focus_mode = Control.FOCUS_NONE
	give.disabled = true
	row.add_child(give)
	give.stack = _player.cards.stack_at(offer.give_slot)
	var arrow: Label = Label.new()
	arrow.text = "→"
	arrow.add_theme_font_size_override("font_size", 32)
	row.add_child(arrow)
	var receive: CardView = CardView.new()
	receive.focus_mode = Control.FOCUS_NONE
	receive.disabled = true
	row.add_child(receive)
	receive.stack = CardStack.new(offer.receive)
	var accept: Button = Button.new()
	accept.text = "Trade"
	accept.custom_minimum_size = Vector2(120, 40)
	accept.disabled = _player.cards.stack_at(offer.give_slot) == null
	accept.pressed.connect(_on_trade.bind(index))
	row.add_child(accept)
	return row


func _on_trade(index: int) -> void:
	var offer: Offer = _offers[index]
	if _player.cards.stack_at(offer.give_slot) == null:
		return
	# The new card goes in its own rank slot (or the backpack).
	var given: CardStack = _player.cards.stack_at(offer.give_slot)
	var received: CardStack = CardStack.new(offer.receive)
	if CardInventory.can_hold(offer.give_slot, offer.receive):
		_player.cards.set_stack(offer.give_slot, received)
	else:
		_player.cards.set_stack(offer.give_slot, null)
		if not _player.cards.place(received):
			_player.cards.set_stack(offer.give_slot, given)
			_title.text = "No room for %s: free its slot or a backpack slot" % offer.receive.label()
			return
	_title.text = "Traded for %s" % offer.receive.label()
	# Other offers that gave away the same slot are no longer valid.
	var remaining: Array[Offer] = []
	for other: Offer in _offers:
		if other != offer and other.give_slot != offer.give_slot:
			remaining.append(other)
	_offers = remaining
	_rebuild()


func _on_reroll() -> void:
	if _free_rerolls > 0:
		_free_rerolls -= 1
	elif not _player.wallet.spend(economy.units(economy.reroll)):
		return
	_roll()
	_rebuild()
