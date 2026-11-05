class_name MirrorScreen
extends NexusMenu
## The Mirror: permanent upgrades bought in ranks with Reagents. They apply
## at the start of every run.

const PIP_OWNED: String = "◆"
const PIP_EMPTY: String = "◇"
## Debug builds only, until Reagents can be found in runs.
const DEBUG_GRANT: int = 50


func rebuild() -> void:
	_title.text = "The Mirror"
	_subtitle.text = "%d Reagents" % MetaProgress.reagents
	clear_body()
	var grid: GridContainer = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 10)
	_body.add_child(grid)
	var first: Button = null
	var board: UpgradeBoard = MetaProgress.board()
	for upgrade: UpgradeData in board.upgrades:
		var button: Button = _add_row(grid, upgrade)
		if first == null and not button.disabled:
			first = button
	if OS.is_debug_build():
		var grant: Button = Button.new()
		grant.text = "Debug: +%d Reagents" % DEBUG_GRANT
		grant.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		grant.pressed.connect(_on_debug_grant)
		_body.add_child(grant)
	if first != null:
		first.grab_focus.call_deferred()
	else:
		focus_close()


func _add_row(grid: GridContainer, upgrade: UpgradeData) -> Button:
	var rank: int = MetaProgress.rank_of(upgrade.id)
	var name_label: Label = make_label(upgrade.display_name, 18)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	grid.add_child(name_label)
	var pips: String = PIP_OWNED.repeat(rank) + PIP_EMPTY.repeat(upgrade.max_rank() - rank)
	grid.add_child(make_label(pips, 18))
	var effect: String = upgrade.describe(rank) if rank > 0 else "—"
	if rank < upgrade.max_rank():
		effect += "   →   " + upgrade.describe(rank + 1)
	var effect_label: Label = make_label(effect, 15)
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	effect_label.custom_minimum_size = Vector2(380, 0)
	grid.add_child(effect_label)
	var buy: Button = Button.new()
	buy.custom_minimum_size = Vector2(150, 36)
	var cost: int = upgrade.cost_after(rank)
	if cost < 0:
		buy.text = "Maxed"
		buy.disabled = true
	else:
		buy.text = "%d Reagents" % cost
		buy.disabled = MetaProgress.reagents < cost
	buy.pressed.connect(_on_buy.bind(upgrade))
	grid.add_child(buy)
	return buy


func _on_buy(upgrade: UpgradeData) -> void:
	if MetaProgress.buy_rank(upgrade):
		rebuild()


func _on_debug_grant() -> void:
	MetaProgress.add_reagents(DEBUG_GRANT)
	rebuild()
