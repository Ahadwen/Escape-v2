class_name CardPickupScreen
extends Control
## Shown when you pick up a card (the game pauses). Your deck in V1's layout
## (Ace, ranks 2-K, backpack) and the new card, which waits in its own spot.
## A card can only sit in its own rank's slot or the backpack. Mouse/touch:
## drag a card onto another spot to move or swap. Gamepad (or clicking):
## A/click a card to pick it up, then A/click its destination. Discard; Done.
## Whatever is left in the "new card" spot is discarded. An A♦ can upgrade
## the new card.

signal closed

const NEW_INDEX: int = CardInventory.SLOT_COUNT

var _player: Player
var _library: CardLibrary
var _working: Array[CardStack] = []
## The offered card's stack (tracked wherever it's moved to).
var _offered: CardStack
var _selected: int = -1
var _views: Array[CardView] = []
var _title: Label
var _hint: Label
var _details: Label
var _upgrade_button: Button
var _equip_button: Button
var _absorb_button: Button
var _discard_button: Button
var _done_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0, 0, 0, 0.65)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	center.add_child(column)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 28)
	column.add_child(_title)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)
	_views.resize(NEW_INDEX + 1)
	var deck: HBoxContainer = HBoxContainer.new()
	row.add_child(deck)
	DeckLayout.build(deck, _make_slot_view, 6)
	var offered: CardView = _make_view(NEW_INDEX, "New card", CardView.SIZE, false)
	row.add_child(offered)
	_details = Label.new()
	_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.custom_minimum_size = Vector2(900, 48)
	_details.modulate = Color(1, 1, 1, 0.85)
	column.add_child(_details)
	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_hint)
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	column.add_child(buttons)
	_equip_button = _make_button(buttons, "Equip", _on_equip)
	_upgrade_button = _make_button(buttons, "Use A♦: upgrade", _on_upgrade)
	_absorb_button = _make_button(buttons, "Absorb into K♦", _on_absorb)
	_discard_button = _make_button(buttons, "Discard selected", _on_discard)
	_done_button = _make_button(buttons, "Done", _on_done)


func _make_slot_view(slot: int) -> Control:
	var size: Vector2 = Vector2(96, 64)
	if slot == CardInventory.ACE_SLOT:
		size = Vector2(96, 134)
	elif CardInventory.is_backpack(slot):
		size = Vector2(120, 40)
	return _make_view(slot, CardInventory.slot_label(slot), size, true)


func _make_view(index: int, empty: String, size: Vector2, compact: bool) -> CardView:
	var view: CardView = CardView.new()
	view.index = index
	view.view_size = size
	view.compact = compact
	view.empty_text = empty
	view.pressed.connect(_on_card_pressed.bind(index))
	view.dropped.connect(_on_card_dropped)
	view.mouse_entered.connect(_show_details.bind(index))
	view.focus_entered.connect(_show_details.bind(index))
	_views[index] = view
	return view


## Full text of the card under the cursor (or focused) below the deck.
func _show_details(index: int) -> void:
	var stack: CardStack = _working[index] if index < _working.size() else null
	_details.text = CardView.describe(stack).replace("\n", "  ·  ") if stack != null else ""


func set_library(library: CardLibrary) -> void:
	_library = library


func is_open() -> bool:
	return visible


func open(player: Player, card: CardData, count: int = 1) -> void:
	_player = player
	_working.clear()
	for i: int in CardInventory.SLOT_COUNT:
		var stack: CardStack = player.cards.stack_at(i)
		_working.append(stack.copy() if stack != null else null)
	_offered = CardStack.new(card, count)
	_working.append(_offered)
	_selected = -1
	_title.text = "You found %s" % card.label()
	visible = true
	var pause: PauseController = PauseController.find(get_tree())
	if pause != null:
		pause.push_menu_pause()
	else:
		get_tree().paused = true
	_refresh()
	_views[NEW_INDEX].grab_focus()


func _make_button(parent: Node, label: String, handler: Callable) -> Button:
	var button: Button = Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(150, 44)
	button.pressed.connect(handler)
	parent.add_child(button)
	return button


func _on_card_pressed(index: int) -> void:
	if _selected == -1:
		if _working[index] != null:
			_selected = index
	elif _selected == index:
		_selected = -1
	else:
		_swap(_selected, index)
		_selected = -1
	_refresh()


func _on_card_dropped(from: int, to: int) -> void:
	_swap(from, to)
	_selected = -1
	_refresh()
	_views[to].grab_focus()


## Whether spot `index` may hold this card (the new-card spot holds anything).
static func spot_can_hold(index: int, card: CardData) -> bool:
	return index == NEW_INDEX or CardInventory.can_hold(index, card)


## Swaps two spots if both cards fit where they'd end up.
func _swap(a: int, b: int) -> void:
	var card_a: CardData = _working[a].card if _working[a] != null else null
	var card_b: CardData = _working[b].card if _working[b] != null else null
	if not spot_can_hold(b, card_a) or not spot_can_hold(a, card_b):
		var blocked: CardData = card_a if not spot_can_hold(b, card_a) else card_b
		if blocked.joker:
			_title.text = "Jokers go in the backpack"
		else:
			var own: String = CardInventory.slot_label(CardInventory.rank_slot(blocked))
			_title.text = "%s only fits its own %s slot or the backpack" % [blocked.label(), own]
		return
	var held: CardStack = _working[a]
	_working[a] = _working[b]
	_working[b] = held


## Puts the new card in its rank slot; what was there goes to a free
## backpack slot, or (backpack full) takes the new card's spot.
func _on_equip() -> void:
	var at: int = _working.find(_offered)
	if _offered == null or at != NEW_INDEX:
		return
	var own: int = CardInventory.rank_slot(_offered.card)
	if own == -1:
		return
	var displaced: CardStack = _working[own]
	_working[own] = _offered
	_working[NEW_INDEX] = null
	if displaced != null:
		var spare: int = _free_backpack()
		_working[spare if spare != -1 else NEW_INDEX] = displaced
	_selected = -1
	_refresh()


func _free_backpack() -> int:
	for i: int in range(CardInventory.RANK_SLOTS, CardInventory.SLOT_COUNT):
		if _working[i] == null:
			return i
	return -1


func _on_discard() -> void:
	if _selected != -1:
		_working[_selected] = null
		_selected = -1
	_refresh()


func _on_upgrade() -> void:
	var ace_slot: int = _upgrade_ace_slot()
	var at: int = _working.find(_offered)
	var better: CardData = _upgraded(_offered if at != -1 else null)
	if ace_slot == -1 or better == null:
		return
	_offered = CardStack.new(better, _offered.count)
	_working[at] = _offered
	_working[ace_slot].count -= 1
	if _working[ace_slot].count <= 0:
		_working[ace_slot] = null
	_title.text = "Upgraded to %s" % better.label()
	_refresh()


func _on_absorb() -> void:
	var king: int = _absorb_slot()
	var at: int = _working.find(_offered)
	if king == -1 or at == -1 or _offered.card.tier() != 1:
		return
	_working[king].bonus_stats.append_array(_offered.card.stats)
	_title.text = "%s absorbed into K♦" % _offered.card.label()
	_working[at] = null
	_offered = null
	_refresh()


## Slot index (working copy) of an active K♦ Absorb card, or -1.
func _absorb_slot() -> int:
	for i: int in CardInventory.RANK_SLOTS:
		var stack: CardStack = _working[i]
		if stack != null and stack.card.effect is AbsorbEffect:
			return i
	return -1


func _on_done() -> void:
	_player.cards.replace_all(_working.slice(0, CardInventory.SLOT_COUNT))
	visible = false
	var pause: PauseController = PauseController.find(get_tree())
	if pause != null:
		# Hand over to the normal pause: the first input resumes the game and
		# takes effect, so closing the screen never costs you a hit.
		pause.enter_manual_pause()
		pause.pop_menu_pause()
	else:
		get_tree().paused = false
	closed.emit()


## Slot index (in the working copy) of an active A♦ stack, or -1.
func _upgrade_ace_slot() -> int:
	for i: int in [CardInventory.ACE_SLOT]:
		var stack: CardStack = _working[i]
		if stack != null and stack.card.is_ace() and stack.card.ace_effect is UpgradeAce:
			return i
	return -1


func _upgraded(offered: CardStack) -> CardData:
	if offered == null or offered.card.is_ace() or _library == null:
		return null
	return _library.find(offered.card.suit, offered.card.rank + 1)


func _refresh() -> void:
	for i: int in _views.size():
		_views[i].stack = _working[i]
		_views[i].selected = i == _selected
	var leftover: CardStack = _working[NEW_INDEX]
	if _selected != -1:
		var held: String = _working[_selected].card.label()
		_hint.text = "%s picked up: choose where to drop it (swaps), or discard it." % held
	elif leftover != null:
		_hint.text = (
			"Drag %s into a slot (or select it, then a slot). Left here, it's discarded."
			% leftover.card.label()
		)
	else:
		_hint.text = "Drag or select a card to move it."
	var offered_here: bool = _working.has(_offered)
	var upgradable: bool = (
		_upgrade_ace_slot() != -1 and offered_here and _upgraded(_offered) != null
	)
	_upgrade_button.visible = _upgrade_ace_slot() != -1
	var can_absorb: bool = (
		_absorb_slot() != -1 and _offered != null and offered_here and _offered.card.tier() == 1
	)
	_absorb_button.visible = can_absorb
	_upgrade_button.disabled = not upgradable
	_discard_button.disabled = _selected == -1
	var waiting: bool = _offered != null and _working.find(_offered) == NEW_INDEX
	_equip_button.disabled = not waiting or CardInventory.rank_slot(_offered.card) == -1
	if waiting and CardInventory.rank_slot(_offered.card) != -1:
		_equip_button.text = (
			"Equip in %s slot" % CardInventory.slot_label(CardInventory.rank_slot(_offered.card))
		)
