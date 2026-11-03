class_name CardView
extends Button
## A card as a selectable button: rank+suit, stats and effect text.

const SIZE: Vector2 = Vector2(150, 190)

var stack: CardStack:
	set(value):
		stack = value
		_refresh()
var selected: bool = false:
	set(value):
		selected = value
		_refresh()
## Shown when the slot is empty.
var empty_text: String = "Empty"


func _ready() -> void:
	custom_minimum_size = SIZE
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	clip_text = false
	alignment = HORIZONTAL_ALIGNMENT_CENTER
	focus_mode = Control.FOCUS_ALL
	_refresh()


func _refresh() -> void:
	if not is_inside_tree():
		return
	if stack == null:
		text = empty_text
		modulate = Color(1, 1, 1, 0.55)
	else:
		text = describe(stack)
		modulate = stack.card.color().lerp(Color.WHITE, 0.55)
	if selected:
		modulate = Color(1.0, 1.0, 0.55)


static func describe(card_stack: CardStack) -> String:
	var card: CardData = card_stack.card
	var lines: PackedStringArray = PackedStringArray()
	var heading: String = card.label()
	if card_stack.count > 1:
		heading += "  ×%d" % card_stack.count
	lines.append(heading)
	if not card.title.is_empty():
		lines.append(card.title)
	lines.append_array(card.stat_lines())
	if not card.description.is_empty():
		lines.append(card.description)
	return "\n".join(lines)
