class_name LootService
extends Node
## Hands out loot: rolls a card and gold for a chest, stacks aces straight
## into an existing stack, otherwise opens the pickup screen.

signal card_offered(card: CardData)

const GROUP: StringName = &"loot_service"

@export var loot_table: LootTable
@export var economy: GoldEconomy
@export var pickup_screen: CardPickupScreen


static func find(tree: SceneTree) -> LootService:
	return tree.get_first_node_in_group(GROUP) as LootService


func _enter_tree() -> void:
	add_to_group(GROUP)


## Debug builds: F3 gives the player a chest's worth of loot.
func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not event.is_action_pressed(InputActions.DEBUG_GIVE_LOOT):
		return
	var player: Player = get_tree().get_first_node_in_group(Player.GROUP) as Player
	if player != null and not player.is_dead:
		open_chest(player)


func open_chest(player: Player) -> void:
	if loot_table == null:
		return
	var card: CardData = loot_table.roll()
	if card == null:
		return
	var gold: int = economy.card_pickup_gold(player.stats.get_value(StatIds.GOLD_PER_PICKUP))
	gold += economy.chest_bonus_gold()
	player.wallet.add(gold)
	offer(player, card)


## Offers a card to the player.
func offer(player: Player, card: CardData, count: int = 1) -> void:
	card_offered.emit(card)
	var existing: int = player.cards.stack_slot_for(card)
	if existing != -1:
		player.cards.add_to_stack(existing, count)
		return
	if pickup_screen != null:
		pickup_screen.open(player, card, count)
	else:
		var empty: int = player.cards.first_empty_slot()
		if empty != -1:
			player.cards.set_stack(empty, CardStack.new(card, count))
