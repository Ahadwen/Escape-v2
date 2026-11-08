extends "res://tests/framework/test_case.gd"

const CardInventoryScript := preload("res://actors/components/card_inventory.gd")
const StatsComponentScript := preload("res://actors/components/stats_component.gd")
const CardDataScript := preload("res://items/card_data.gd")
const CardStatScript := preload("res://items/card_stat.gd")
const CardStackScript := preload("res://items/card_stack.gd")
const LibraryScript := preload("res://items/card_library.gd")
const UpgradeAceScript := preload("res://items/aces/upgrade_ace.gd")

var inventory: CardInventory
var stats: StatsComponent


func _card(suit: int, rank: int, stat: StringName = &"", value: float = 0.0) -> CardData:
	var card: CardData = CardDataScript.new()
	card.suit = suit as CardData.Suit
	card.rank = rank
	if stat != &"":
		var line: CardStat = CardStatScript.new()
		line.stat = stat
		line.value = value
		var lines: Array[CardStat] = [line]
		card.stats = lines
	return card


func _joker() -> CardData:
	var card: CardData = CardDataScript.new()
	card.joker = true
	return card


func before_each() -> void:
	stats = add_to_tree(StatsComponentScript.new()) as StatsComponent
	stats.block.set_base(StatIds.ARMOUR, 10.0)
	inventory = CardInventoryScript.new()
	inventory.stats = stats
	add_to_tree(inventory)


func test_has_six_empty_slots() -> void:
	assert_eq(inventory.slots.size(), 6)
	assert_eq(inventory.first_empty_slot(), 0)


func test_card_stats_apply_and_remove() -> void:
	inventory.set_stack(0, CardStackScript.new(_card(0, 2, StatIds.ARMOUR, 4.0)))
	assert_almost_eq(stats.get_value(StatIds.ARMOUR), 14.0)
	inventory.set_stack(0, null)
	assert_almost_eq(stats.get_value(StatIds.ARMOUR), 10.0)


func test_stats_from_several_cards_add_up() -> void:
	inventory.set_stack(0, CardStackScript.new(_card(0, 2, StatIds.ARMOUR, 4.0)))
	inventory.set_stack(3, CardStackScript.new(_card(0, 6, StatIds.ARMOUR, 3.0)))
	assert_almost_eq(stats.get_value(StatIds.ARMOUR), 17.0)


func test_swap_keeps_stats() -> void:
	inventory.set_stack(0, CardStackScript.new(_card(0, 2, StatIds.ARMOUR, 4.0)))
	inventory.swap(0, 4)
	assert_null(inventory.stack_at(0))
	assert_not_null(inventory.stack_at(4))
	assert_almost_eq(stats.get_value(StatIds.ARMOUR), 14.0)


func test_aces_stack_in_one_slot() -> void:
	var ace: CardData = _card(0, 1)
	inventory.set_stack(2, CardStackScript.new(ace))
	assert_eq(inventory.stack_slot_for(ace), 2)
	inventory.add_to_stack(2, 2)
	assert_eq(inventory.stack_at(2).count, 3)


func test_non_aces_never_stack() -> void:
	var card: CardData = _card(1, 4)
	inventory.set_stack(0, CardStackScript.new(card))
	assert_eq(inventory.stack_slot_for(card), -1)


func test_consuming_last_ace_empties_slot() -> void:
	inventory.set_stack(1, CardStackScript.new(_card(2, 1), 1))
	inventory.consume_one(1)
	assert_null(inventory.stack_at(1))


func test_ace_index_follows_slot_order() -> void:
	inventory.set_stack(3, CardStackScript.new(_card(0, 1)))
	inventory.set_stack(1, CardStackScript.new(_card(3, 1)))
	assert_eq(inventory.ace_slot_by_index(0), 1)
	assert_eq(inventory.ace_slot_by_index(1), 3)
	assert_eq(inventory.ace_slot_by_index(2), -1)


func test_selected_ace_cycles() -> void:
	inventory.set_stack(0, CardStackScript.new(_card(0, 1)))
	inventory.set_stack(2, CardStackScript.new(_card(1, 1)))
	assert_eq(inventory.selected_ace_slot, 0)
	inventory.cycle_selected_ace(1)
	assert_eq(inventory.selected_ace_slot, 2)
	inventory.cycle_selected_ace(1)
	assert_eq(inventory.selected_ace_slot, 0)


func test_pickup_screen_only_ace_cannot_be_used_in_field() -> void:
	var ace: CardData = _card(1, 1)
	ace.ace_effect = UpgradeAceScript.new()
	inventory.set_stack(0, CardStackScript.new(ace))
	assert_false(inventory.use_ace(0, null))
	assert_not_null(inventory.stack_at(0))


func test_tiers_and_labels() -> void:
	assert_eq(_card(0, 1).tier(), 0)
	assert_eq(_card(0, 6).tier(), 1)
	assert_eq(_card(0, 7).tier(), 2)
	assert_eq(_card(0, 12).tier(), 3)
	assert_eq(_card(0, 4).label(), "4♥")
	assert_eq(_card(3, 13).label(), "K♠")


func test_library_finds_by_suit_and_rank() -> void:
	var library: CardLibrary = LibraryScript.new()
	var four: CardData = _card(0, 4)
	var five: CardData = _card(0, 5)
	var cards: Array[CardData] = [four, five]
	library.cards = cards
	assert_eq(library.find(CardData.Suit.HEARTS, 5), five)
	assert_null(library.find(CardData.Suit.SPADES, 5))


func test_trade_candidates_same_or_one_higher_and_never_t3() -> void:
	var trader: GDScript = load("res://ui/shop/trader_screen.gd")
	var four_h: CardData = _card(0, 4)
	var all_cards: Array[CardData] = [
		four_h, _card(1, 4), _card(2, 5), _card(3, 6), _card(0, 3), _card(0, 1), _joker()
	]
	var found: Array[CardData] = trader.candidates_for(four_h, all_cards)
	assert_eq(found.size(), 2)
	for card: CardData in found:
		assert_true(card.rank == 4 or card.rank == 5)
		assert_false(card.same_card(four_h))
	var ten_s: CardData = _card(3, 10)
	var with_jack: Array[CardData] = [_card(0, 11), _card(1, 10)]
	var from_ten: Array[CardData] = trader.candidates_for(ten_s, with_jack)
	assert_eq(from_ten.size(), 1)
	assert_eq(from_ten[0].rank, 10)


func test_card_value() -> void:
	assert_eq(_card(0, 7).value(), 7)
	assert_eq(_card(0, 12).value(), 12)
	assert_eq(_card(0, 1).value(), 0)
	assert_eq(_joker().value(), 0)


func test_chests_drop_ace_to_ten_with_t2s_rarer() -> void:
	var loot: LootTable = load("res://items/data/chest_loot.tres") as LootTable
	seed(4)
	var counts: Dictionary = {0: 0, 1: 0, 2: 0, 3: 0}
	for i: int in 3000:
		var card: CardData = loot.roll()
		if card != null and not card.joker:
			counts[card.tier()] += 1
	assert_eq(counts[3], 0, "no J/Q/K from chests")
	assert_true(counts[2] > 200, "T2s drop: %d" % counts[2])
	assert_true(counts[1] > counts[2] * 2, "T1s are more common")
	assert_true(counts[0] > 0, "aces still drop")
