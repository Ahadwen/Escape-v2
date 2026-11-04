class_name AceBar
extends Control
## Cast icons for held aces, in a row just above the ability slots. Each icon
## shows the ace, how many you hold and its key (PC: 1-4); on gamepad/touch
## the selected ace is outlined. Hidden when you hold no aces.

const ICON_SIZE: Vector2 = Vector2(48.0, 48.0)
## How far above the top of the ability bar the row sits.
const RAISE: float = 58.0

@export var cards: CardInventory

var _row: HBoxContainer
var _show_key_hints: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 8)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Full width, centred, just above this control's top edge.
	_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_row.offset_top = -RAISE
	_row.offset_bottom = -RAISE + ICON_SIZE.y
	add_child(_row)
	if cards != null:
		cards.changed.connect(_refresh)
	_refresh()


## Key hints (1-4) only make sense on PC; elsewhere the selection is shown.
func set_scheme(kind: InputRouter.SchemeKind) -> void:
	_show_key_hints = kind == InputRouter.SchemeKind.PC
	_refresh()


func _refresh() -> void:
	if _row == null:
		return
	for child: Node in _row.get_children():
		child.queue_free()
	if cards == null:
		return
	var aces: Array[int] = cards.ace_slots()
	for i: int in aces.size():
		var slot: int = aces[i]
		var key: String = str(i + 1) if _show_key_hints and i < InputActions.ACE_KEY_COUNT else ""
		var selected: bool = not _show_key_hints and slot == cards.selected_ace_slot
		_row.add_child(_build_icon(cards.stack_at(slot), key, selected))


func _build_icon(stack: CardStack, key: String, selected: bool) -> Control:
	var icon: Panel = Panel.new()
	icon.custom_minimum_size = ICON_SIZE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = stack.card.color().darkened(0.45)
	style.set_corner_radius_all(int(ICON_SIZE.x * 0.5))
	style.set_border_width_all(3 if selected else 2)
	style.border_color = Color(1.0, 1.0, 0.55) if selected else stack.card.color().lightened(0.3)
	icon.add_theme_stylebox_override("panel", style)
	var symbol: Label = _label(stack.card.label(), 17, Color.WHITE)
	symbol.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_child(symbol)
	if stack.count > 1:
		var count: Label = _label("×%d" % stack.count, 12, Color(1.0, 0.95, 0.7))
		count.position = Vector2(ICON_SIZE.x - 20.0, ICON_SIZE.y - 16.0)
		icon.add_child(count)
	if not key.is_empty():
		var key_label: Label = _label(key, 12, Color(0.85, 0.85, 0.85))
		key_label.position = Vector2(-2.0, -16.0)
		icon.add_child(key_label)
	return icon


func _label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
