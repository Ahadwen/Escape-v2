class_name CardPickupScreen
extends Control
## Shown when you pick up a card (the game pauses). Your 5 slots and the new
## card: select one card, then another to swap them; discard; Done. Whatever
## is left in the "new card" spot when you're done is discarded.
## An A♦ in your slots can upgrade the offered card one rank.

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
var _upgrade_button: Button
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
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)
	for i: int in NEW_INDEX + 1:
		if i == NEW_INDEX:
			var gap: Control = Control.new()
			gap.custom_minimum_size = Vector2(28, 0)
			row.add_child(gap)
		var view: CardView = CardView.new()
		view.empty_text = "New card" if i == NEW_INDEX else "Slot %d\nempty" % (i + 1)
		view.pressed.connect(_on_card_pressed.bind(i))
		row.add_child(view)
		_views.append(view)
	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_hint)
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	column.add_child(buttons)
	_upgrade_button = _make_button(buttons, "Use A♦: upgrade", _on_upgrade)
	_discard_button = _make_button(buttons, "Discard selected", _on_discard)
	_done_button = _make_button(buttons, "Done", _on_done)


func set_library(library: CardLibrary) -> void:
	_library = library


func is_open() -> bool:
	return visible


func open(player: Player, card: CardData, count: int = 1) -> void:
	_player = player
	_working.clear()
	for i: int in CardInventory.SLOT_COUNT:
		var stack: CardStack = player.cards.stack_at(i)
		_working.append(CardStack.new(stack.card, stack.count) if stack != null else null)
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
	# Default: put it in the first empty slot if there is one.
	var empty: int = player.cards.first_empty_slot()
	if empty != -1:
		_swap(empty, NEW_INDEX)
		_views[empty].grab_focus()
	else:
		_views[NEW_INDEX].grab_focus()
	_refresh()


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


func _swap(a: int, b: int) -> void:
	var held: CardStack = _working[a]
	_working[a] = _working[b]
	_working[b] = held


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


func _on_done() -> void:
	_player.cards.replace_all(_working.slice(0, CardInventory.SLOT_COUNT))
	visible = false
	var pause: PauseController = PauseController.find(get_tree())
	if pause != null:
		pause.pop_menu_pause()
	else:
		get_tree().paused = false
	closed.emit()


## Slot index (in the working copy) of an A♦ stack, or -1.
func _upgrade_ace_slot() -> int:
	for i: int in CardInventory.SLOT_COUNT:
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
		_hint.text = "Select another card to swap with, or discard it."
	elif leftover != null:
		_hint.text = "%s will be discarded when you're done." % leftover.card.label()
	else:
		_hint.text = "Select a card to move it."
	var offered_here: bool = _working.has(_offered)
	var upgradable: bool = (
		_upgrade_ace_slot() != -1 and offered_here and _upgraded(_offered) != null
	)
	_upgrade_button.visible = _upgrade_ace_slot() != -1
	_upgrade_button.disabled = not upgradable
	_discard_button.disabled = _selected == -1
