class_name CardBar
extends Control
## The deck at a glance under the HP bar, laid out like V1: the Ace slot,
## ranks 2-K in two rows, the backpack on the right (spares, inactive), then
## gold. Aces are cast from their icon above the ability bar (AceBar).

const TILE_SIZE: Vector2 = Vector2(40, 30)
const PACK_TILE_SIZE: Vector2 = Vector2(58, 18)

@export var cards: CardInventory
@export var wallet: Wallet

var _labels: Array[Label] = []
var _panels: Array[PanelContainer] = []
var _gold: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row: HBoxContainer = HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	var holder: HBoxContainer = HBoxContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(holder)
	_labels.resize(CardInventory.SLOT_COUNT)
	_panels.resize(CardInventory.SLOT_COUNT)
	DeckLayout.build(holder, _make_tile, 3)
	_gold = Label.new()
	_gold.add_theme_font_size_override("font_size", 18)
	_gold.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	_gold.custom_minimum_size = Vector2(80, 0)
	_gold.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_gold)
	if cards != null:
		cards.changed.connect(_refresh)
	if wallet != null:
		wallet.changed.connect(func(_gold_amount: int) -> void: _refresh())
	_refresh()


## Kept for the HUD scheme switch; cards look the same on every scheme.
func set_scheme(_kind: InputRouter.SchemeKind) -> void:
	_refresh()


func _make_tile(slot: int) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = (PACK_TILE_SIZE if CardInventory.is_backpack(slot) else TILE_SIZE)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label: Label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	_panels[slot] = panel
	_labels[slot] = label
	return panel


func _refresh() -> void:
	if cards == null or _labels.is_empty():
		return
	for i: int in CardInventory.SLOT_COUNT:
		var stack: CardStack = cards.stack_at(i)
		var label: Label = _labels[i]
		if stack == null:
			label.text = CardInventory.slot_label(i) if not CardInventory.is_backpack(i) else "·"
			_panels[i].modulate = Color(1, 1, 1, 0.35)
			continue
		label.text = stack.card.label()
		if stack.count > 1:
			label.text += "×%d" % stack.count
		var tint: Color = stack.card.color().lerp(Color.WHITE, 0.4)
		# Backpack cards are spares: shown dimmer.
		if CardInventory.is_backpack(i):
			tint.a = 0.6
		_panels[i].modulate = tint
	_gold.text = "%d g" % (wallet.gold if wallet != null else 0)
