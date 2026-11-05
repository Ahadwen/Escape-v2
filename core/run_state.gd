class_name RunState
extends RefCounted
## The current run, kept across scene changes (level -> safehouse -> level):
## level number, run seed, cards and gold. HP isn't kept: it's restored at
## the start of every level.

const LEVEL_COUNT: int = 5
const LEVEL_SCENE: String = "res://world/levels/level.tscn"
const SAFEHOUSE_SCENE: String = "res://world/safehouse/safehouse_lobby.tscn"
const NEXUS_SCENE: String = "res://world/nexus/nexus.tscn"

static var active: bool = false
static var run_seed: int = 0
## 0-based: 0 = level 1.
static var level_index: int = 0
static var gold: int = 0
## Saved card stacks (copies), one per slot (null = empty).
static var cards: Array[CardStack] = []
## How the last run ended (shown in the Nexus). Empty before the first run.
static var last_result: String = ""


static func start_new_run(p_seed: int) -> void:
	active = true
	run_seed = p_seed
	level_index = 0
	gold = 0
	cards.clear()


## Ends the run; `result` describes how (shown back in the Nexus).
static func end_run(result: String = "") -> void:
	active = false
	if not result.is_empty():
		last_result = result


static func is_final_level() -> bool:
	return level_index >= LEVEL_COUNT - 1


## Saves the player's cards and gold into the run.
static func save_from(player: Player) -> void:
	gold = player.wallet.gold
	cards.clear()
	for i: int in CardInventory.SLOT_COUNT:
		var stack: CardStack = player.cards.stack_at(i)
		if stack == null:
			cards.append(null)
		else:
			var saved: CardStack = stack.copy()
			# Effects are re-created in the next scene.
			saved.effect_instance = null
			cards.append(saved)


## Restores saved cards and gold onto a freshly spawned player.
static func apply_to(player: Player) -> void:
	if not active:
		return
	var stacks: Array[CardStack] = []
	for stack: CardStack in cards:
		stacks.append(stack.copy() if stack != null else null)
	player.cards.replace_all(stacks)
	player.wallet.gold = 0
	player.wallet.add(gold)
