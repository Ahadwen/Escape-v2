class_name CardView
extends Button
## A card as a button: rank+suit, stats and effect text. Can be dragged onto
## another CardView to move/swap (mouse and touch).

## Dragged from `from` onto `to` (indices set by the owner).
signal dropped(from: int, to: int)

const SIZE: Vector2 = Vector2(150, 190)

## Position of this view in its owner's list.
var index: int = -1
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


func _get_drag_data(_at_position: Vector2) -> Variant:
	if stack == null:
		return null
	var preview: Label = Label.new()
	preview.text = stack.card.label()
	preview.add_theme_font_size_override("font_size", 32)
	preview.modulate = stack.card.color().lerp(Color.WHITE, 0.4)
	set_drag_preview(preview)
	return {"card_view_index": index}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and (data as Dictionary).has("card_view_index")


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var from: int = (data as Dictionary)["card_view_index"]
	if from != index:
		dropped.emit(from, index)


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
