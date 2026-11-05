extends "res://tests/framework/test_case.gd"

const StatBlockScript := preload("res://stats/stat_block.gd")


func before_each() -> void:
	MetaProgress.saving_enabled = false
	MetaProgress.ensure_loaded()
	MetaProgress.reset()


func test_mirror_rows_each_offer_two_options() -> void:
	var board: MirrorBoard = MetaProgress.board()
	assert_eq(board.rows.size(), 6)
	for row: MirrorRow in board.rows:
		assert_not_null(row.option_a, String(row.id))
		assert_not_null(row.option_b, String(row.id))
		assert_ne(row.option_a.id, row.option_b.id)


func test_one_choice_per_row_and_toggle_off() -> void:
	MetaProgress.choose(&"body", &"thick_skin")
	MetaProgress.choose(&"body", &"fleet_foot")
	assert_eq(MetaProgress.choice(&"body"), &"fleet_foot", "the row holds one choice")
	MetaProgress.choose(&"body", &"fleet_foot")
	assert_eq(MetaProgress.choice(&"body"), &"", "choosing it again clears it")


func test_stat_choices_apply_and_swap_cleanly() -> void:
	var block: StatBlock = StatBlockScript.new()
	block.set_base(StatIds.MAX_HP, 400.0)
	block.set_base(StatIds.MOVE_SPEED, 8.0)
	MetaProgress.choose(&"body", &"thick_skin")
	MetaProgress.apply_to(block)
	MetaProgress.apply_to(block)
	assert_almost_eq(block.get_value(StatIds.MAX_HP), 475.0)
	MetaProgress.choose(&"body", &"fleet_foot")
	MetaProgress.apply_to(block)
	assert_almost_eq(block.get_value(StatIds.MAX_HP), 400.0, 0.001, "thick skin removed")
	assert_almost_eq(block.get_value(StatIds.MOVE_SPEED), 8.4)


func test_run_multipliers_combine() -> void:
	assert_almost_eq(MetaProgress.threat_multiplier(), 1.0)
	MetaProgress.choose(&"pace", &"thrill_seeker")
	MetaProgress.choose(&"fortune", &"lucky_finds")
	assert_almost_eq(MetaProgress.threat_multiplier(), 1.2)
	assert_almost_eq(MetaProgress.chest_multiplier(), 1.5 * 1.3)


func test_roster_starts_with_the_knight_selected() -> void:
	assert_true(MetaProgress.is_unlocked(&"knight"))
	assert_eq(MetaProgress.selected_character().id, &"knight")
	MetaProgress.select_character(&"nobody")
	assert_eq(MetaProgress.selected_character().id, &"knight", "locked ids are ignored")
