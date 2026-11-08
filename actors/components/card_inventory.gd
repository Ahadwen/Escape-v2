class_name CardInventory
extends Node
## Six card slots. Applies held cards' stats, stacks aces and uses them.

signal changed

const SLOT_COUNT: int = 6
const STAT_SOURCE: StringName = &"cards"

@export var stats: StatsComponent
## The owning player (card effects and aces act on it).
@export var player: Player

## One entry per slot; null = empty.
var slots: Array[CardStack] = []
## For gamepad/touch: which slot's ace is selected for use.
var selected_ace_slot: int = -1

var _equipped: Array[CardEffectInstance] = []


func _init() -> void:
	slots.resize(SLOT_COUNT)


func stack_at(slot: int) -> CardStack:
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
	var stack: CardStack = stack_at(slot)
	if stack == null or not stack.card.is_ace() or stack.card.ace_effect == null:
		return false
	if stack.card.ace_effect.is_pickup_screen_only():
		return false
	if not stack.card.ace_effect.use(player):
		return false
	var card: CardData = stack.card
	consume_one(slot)
	if player != null:
		player.events.ace_used.emit(card)
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
	_sync_effects()
	changed.emit()


func _physics_process(delta: float) -> void:
	for stack: CardStack in slots:
		if stack != null and stack.effect_instance != null:
			stack.effect_instance.tick(delta)


## Equips effects for newly held cards and unequips ones no longer held.
func _sync_effects() -> void:
	if player == null:
		return
	var held: Array[CardEffectInstance] = []
	for stack: CardStack in slots:
		if stack == null or stack.card.effect == null:
			continue
		if stack.effect_instance == null:
			stack.effect_instance = stack.card.effect.create_instance()
			stack.effect_instance.equip(player, stack.card.effect)
		held.append(stack.effect_instance)
	for instance: CardEffectInstance in _equipped:
		if not instance in held:
			instance.unequip()
	_equipped = held


func _apply_stats() -> void:
	if stats == null:
		return
	stats.block.remove_modifiers_from(STAT_SOURCE)
	for stack: CardStack in slots:
		if stack == null:
			continue
		for line: CardStat in stack.all_stats():
			stats.block.add_modifier(
				StatModifier.new(line.stat, StatModifier.Type.FLAT, line.value, STAT_SOURCE)
			)
