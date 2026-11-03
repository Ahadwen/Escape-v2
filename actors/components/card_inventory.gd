class_name CardInventory
extends Node
## Five card slots. Applies held cards' stats, stacks aces and uses them.

signal changed

const SLOT_COUNT: int = 5
const STAT_SOURCE: StringName = &"cards"

@export var stats: StatsComponent

## One entry per slot; null = empty.
var slots: Array[CardStack] = []
## For gamepad/touch: which slot's ace is selected for use.
var selected_ace_slot: int = -1


func _init() -> void:
	slots.resize(SLOT_COUNT)


func get_stack(slot: int) -> CardStack:
	return slots[slot] if slot >= 0 and slot < SLOT_COUNT else null


func set_stack(slot: int, stack: CardStack) -> void:
	slots[slot] = stack
	_refresh()


## Replaces every slot at once (e.g. after the pickup screen).
func replace_all(stacks: Array[CardStack]) -> void:
	for i: int in SLOT_COUNT:
		slots[i] = stacks[i] if i < stacks.size() else null
	_refresh()


func swap(a: int, b: int) -> void:
	var held: CardStack = slots[a]
	slots[a] = slots[b]
	slots[b] = held
	_refresh()


func first_empty_slot() -> int:
	for i: int in SLOT_COUNT:
		if slots[i] == null:
			return i
	return -1


## Slot holding a stack of this ace, or -1.
func stack_slot_for(card: CardData) -> int:
	if not card.is_ace():
		return -1
	for i: int in SLOT_COUNT:
		if slots[i] != null and slots[i].card == card:
			return i
	return -1


func add_to_stack(slot: int, count: int) -> void:
	slots[slot].count += count
	_refresh()


func ace_slots() -> Array[int]:
	var found: Array[int] = []
	for i: int in SLOT_COUNT:
		if slots[i] != null and slots[i].card.is_ace():
			found.append(i)
	return found


## Ace stack number `index` (0 = first ace stack in slot order), or -1.
func ace_slot_by_index(index: int) -> int:
	var aces: Array[int] = ace_slots()
	return aces[index] if index >= 0 and index < aces.size() else -1


func cycle_selected_ace(step: int) -> void:
	var aces: Array[int] = ace_slots()
	if aces.is_empty():
		selected_ace_slot = -1
	else:
		var at: int = aces.find(selected_ace_slot)
		selected_ace_slot = aces[posmod(at + step, aces.size())] if at != -1 else aces[0]
	changed.emit()


## Uses one ace from a slot. Returns true if one was consumed.
func use_ace(slot: int, player: Player) -> bool:
	var stack: CardStack = get_stack(slot)
	if stack == null or not stack.card.is_ace() or stack.card.ace_effect == null:
		return false
	if stack.card.ace_effect.is_pickup_screen_only():
		return false
	if not stack.card.ace_effect.use(player):
		return false
	consume_one(slot)
	return true


func consume_one(slot: int) -> void:
	var stack: CardStack = slots[slot]
	stack.count -= 1
	if stack.count <= 0:
		slots[slot] = null
	_refresh()


func _refresh() -> void:
	if selected_ace_slot != -1:
		var stack: CardStack = slots[selected_ace_slot]
		if stack == null or not stack.card.is_ace():
			selected_ace_slot = -1
	if selected_ace_slot == -1:
		var aces: Array[int] = ace_slots()
		if not aces.is_empty():
			selected_ace_slot = aces[0]
	_apply_stats()
	changed.emit()


func _apply_stats() -> void:
	if stats == null:
		return
	stats.block.remove_modifiers_from(STAT_SOURCE)
	for stack: CardStack in slots:
		if stack == null:
			continue
		for line: CardStat in stack.card.stats:
			stats.block.add_modifier(
				StatModifier.new(line.stat, StatModifier.Type.FLAT, line.value, STAT_SOURCE)
			)
