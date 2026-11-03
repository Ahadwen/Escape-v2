class_name DebugCardPicker
extends Control
## Debug builds only: F4 opens a list of every card; double-click / Enter /
## A gives it to you (through the normal pickup screen).

@export var library: CardLibrary

var _list: ItemList


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.is_debug_build():
		queue_free()
		return
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(420, 520)
	position -= custom_minimum_size * 0.5
	visible = false
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	panel.add_child(column)
	var title: Label = Label.new()
	title.text = "Debug: pick a card (F4 to close)"
	column.add_child(title)
	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_activated.connect(_on_item_activated)
	column.add_child(_list)
	if library != null:
		var cards: Array[CardData] = library.cards.duplicate()
		cards.sort_custom(_sort_cards)
		for card: CardData in cards:
			var text: String = card.label()
			if not card.title.is_empty():
				text += "  " + card.title
			var index: int = _list.add_item(text)
			_list.set_item_metadata(index, card)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.DEBUG_CARD_PICKER):
		_set_open(not visible)
		get_viewport().set_input_as_handled()


func _set_open(open: bool) -> void:
	if open == visible:
		return
	visible = open
	var pause: PauseController = PauseController.find(get_tree())
	if pause != null:
		if open:
			pause.push_menu_pause()
		else:
			pause.pop_menu_pause()
	if open:
		_list.grab_focus()


func _on_item_activated(index: int) -> void:
	var card: CardData = _list.get_item_metadata(index) as CardData
	var player: Player = get_tree().get_first_node_in_group(Player.GROUP) as Player
	var loot: LootService = LootService.find(get_tree())
	_set_open(false)
	if card != null and player != null and loot != null:
		loot.offer(player, card)


static func _sort_cards(a: CardData, b: CardData) -> bool:
	if a.suit != b.suit:
		return a.suit < b.suit
	var ra: int = 14 if a.rank == CardData.ACE else a.rank
	var rb: int = 14 if b.rank == CardData.ACE else b.rank
	return ra < rb
