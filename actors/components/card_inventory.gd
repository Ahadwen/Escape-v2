class_name CardInventory
extends Node
## V1-style deck: one slot per rank (A, 2 ... K), each holding only a card of
## that rank, plus a 3-slot backpack for spares (any card, jokers included).
## Only cards in rank slots are active (stats, effects; the Ace slot's Ace
## is the one you use). Slots 0-12 are ranks A-K, 13-15 the backpack.

signal changed

const RANK_SLOTS: int = 13
const BACKPACK_SLOTS: int = 3
const SLOT_COUNT: int = RANK_SLOTS + BACKPACK_SLOTS
const ACE_SLOT: int = 0
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


## The rank slot for a card's rank (A = 0 ... K = 12), or -1 (jokers).
static func rank_slot(card: CardData) -> int:
	if card == null or card.joker or card.rank < 1 or card.rank > RANK_SLOTS:
		return -1
	return card.rank - 1


static func is_backpack(slot: int) -> bool:
	return slot >= RANK_SLOTS and slot < SLOT_COUNT


## Whether a slot may hold this card (backpack: anything; rank slot: its rank).
static func can_hold(slot: int, card: CardData) -> bool:
	if card == null or is_backpack(slot):
		return true
	return slot >= 0 and slot < RANK_SLOTS and rank_slot(card) == slot


## Short label for a slot ("A", "7", "K", "Pack 1").
static func slot_label(slot: int) -> String:
	if is_backpack(slot):
		return "Pack %d" % (slot - RANK_SLOTS + 1)
	return CardData.rank_text(slot + 1)


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


## Where a new card would go: its rank slot if free, else the first free
## backpack slot, else -1.
func free_slot_for(card: CardData) -> int:
	var own: int = rank_slot(card)
	if own != -1 and slots[own] == null:
		return own
	for i: int in range(RANK_SLOTS, SLOT_COUNT):
		if slots[i] == null:
			return i
	return -1


## Puts a card in its free rank slot or the backpack. Returns false if full.
func place(stack: CardStack) -> bool:
	var slot: int = free_slot_for(stack.card)
	if slot == -1:
		return false
	set_stack(slot, stack)
	return true


## Whether this exact card (suit and rank) is held anywhere.
func holds(card: CardData) -> bool:
	for stack: CardStack in slots:
		if stack != null and stack.card.same_card(card):
			return true
	return false


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


## Usable aces: only the one in the Ace slot (backpack aces are spares).
func ace_slots() -> Array[int]:
	var found: Array[int] = []
	if slots[ACE_SLOT] != null and slots[ACE_SLOT].card.is_ace():
		found.append(ACE_SLOT)
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


## Cards in rank slots (the active ones).
func active_stacks() -> Array[CardStack]:
	var active: Array[CardStack] = []
	for i: int in RANK_SLOTS:
		if slots[i] != null:
			active.append(slots[i])
	return active


func _physics_process(delta: float) -> void:
	for stack: CardStack in active_stacks():
		if stack.effect_instance != null:
			stack.effect_instance.tick(delta)


## Equips effects for newly held cards and unequips ones no longer held.
func _sync_effects() -> void:
	if player == null:
		return
	# Cards moved to the backpack stop working (and start fresh if moved back).
	for i: int in range(RANK_SLOTS, SLOT_COUNT):
		var spare: CardStack = slots[i]
		if spare != null and spare.effect_instance != null:
			if spare.effect_instance in _equipped:
				spare.effect_instance.unequip()
				_equipped.erase(spare.effect_instance)
			spare.effect_instance = null
	var held: Array[CardEffectInstance] = []
	for stack: CardStack in active_stacks():
		if stack.card.effect == null:
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
	for stack: CardStack in active_stacks():
		for line: CardStat in stack.all_stats():
			stats.block.add_modifier(
				StatModifier.new(line.stat, StatModifier.Type.FLAT, line.value, STAT_SOURCE)
			)
