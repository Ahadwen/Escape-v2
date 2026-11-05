extends "res://tests/framework/test_case.gd"

const UpgradeScript := preload("res://meta/upgrade_data.gd")
const StatBlockScript := preload("res://stats/stat_block.gd")


func before_each() -> void:
	MetaProgress.saving_enabled = false
	MetaProgress.ensure_loaded()
	MetaProgress.reset()


func _upgrade() -> UpgradeData:
	var upgrade: UpgradeData = UpgradeScript.new()
	upgrade.id = &"test_hp"
	upgrade.stat = StatIds.MAX_HP
	upgrade.value_per_rank = 25.0
	upgrade.costs = PackedInt32Array([10, 20])
	upgrade.description = "%s max HP"
	return upgrade


func test_upgrade_costs_and_text() -> void:
	var upgrade: UpgradeData = _upgrade()
	assert_eq(upgrade.max_rank(), 2)
	assert_eq(upgrade.cost_after(0), 10)
	assert_eq(upgrade.cost_after(2), -1)
	assert_eq(upgrade.describe(2), "+50 max HP")


func test_buying_ranks_spends_reagents() -> void:
	var upgrade: UpgradeData = _upgrade()
	assert_false(MetaProgress.buy_rank(upgrade), "can't afford")
	MetaProgress.add_reagents(25)
	assert_true(MetaProgress.buy_rank(upgrade))
	assert_eq(MetaProgress.rank_of(upgrade.id), 1)
	assert_eq(MetaProgress.reagents, 15)
	assert_false(MetaProgress.buy_rank(upgrade), "rank 2 costs 20")


func test_mirror_upgrades_apply_once_to_stats() -> void:
	var board: UpgradeBoard = MetaProgress.board()
	assert_false(board.upgrades.is_empty())
	var hp: UpgradeData = board.find(&"thick_skin")
	assert_not_null(hp)
	MetaProgress.ranks[String(hp.id)] = 2
	var block: StatBlock = StatBlockScript.new()
	block.set_base(StatIds.MAX_HP, 400.0)
	MetaProgress.apply_to(block)
	MetaProgress.apply_to(block)
	assert_almost_eq(block.get_value(StatIds.MAX_HP), 450.0)


func test_roster_starts_with_the_knight_selected() -> void:
	assert_true(MetaProgress.is_unlocked(&"knight"))
	var chosen: CharacterData = MetaProgress.selected_character()
	assert_not_null(chosen)
	assert_eq(chosen.id, &"knight")
	MetaProgress.select_character(&"nobody")
	assert_eq(MetaProgress.selected_character().id, &"knight", "locked ids are ignored")
