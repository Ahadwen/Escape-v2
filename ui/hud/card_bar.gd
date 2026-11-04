class_name CardBar
extends Control
## The five card slots and gold, under the HP bar. Aces are cast from their
## icons above the ability bar (AceBar), so here they're just cards.

const SLOT_SIZE: Vector2 = Vector2(64, 46)

@export var cards: CardInventory
@export var wallet: Wallet

var _labels: Array[Label] = []
var _panels: Array[PanelContainer] = []
var _gold: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row: HBoxContainer = HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	for i: int in CardInventory.SLOT_COUNT:
		var panel: PanelContainer = PanelContainer.new()
		panel.custom_minimum_size = SLOT_SIZE
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var label: Label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 15)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(label)
		row.add_child(panel)
		_panels.append(panel)
		_labels.append(label)
	_gold = Label.new()
	_gold.add_theme_font_size_override("font_size", 18)
	_gold.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	_gold.custom_minimum_size = Vector2(90, 0)
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


func _refresh() -> void:
	if cards == null:
		return
	for i: int in CardInventory.SLOT_COUNT:
		var stack: CardStack = cards.stack_at(i)
		var label: Label = _labels[i]
		if stack == null:
			label.text = "·"
			_panels[i].modulate = Color(1, 1, 1, 0.4)
			continue
		label.text = stack.card.label()
		_panels[i].modulate = stack.card.color().lerp(Color.WHITE, 0.4)
	_gold.text = "  %d g" % (wallet.gold if wallet != null else 0)
