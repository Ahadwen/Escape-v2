class_name StatsHud
extends Control
## Your stats at a glance in the bottom-right corner, and, while the
## show-stats action is held (Tab / Back), a detailed overlay: every stat and
## what it does, plus the run's context (time, threat, level, zone...) from
## `context_source`. Works while paused; holding it never unpauses.

const GRID_STATS: Array[StringName] = [
	StatIds.MAX_HP,
	StatIds.ARMOUR,
	StatIds.ELEMENTAL_RESIST,
	StatIds.MOVE_SPEED,
	StatIds.ABILITY_HASTE,
	StatIds.WILL,
	StatIds.HP_REGEN,
	StatIds.GOLD_PER_PICKUP,
]
const GRID_SHORT_NAMES: Dictionary[StringName, String] = {
	StatIds.MAX_HP: "HP",
	StatIds.ARMOUR: "Armour",
	StatIds.ELEMENTAL_RESIST: "Resist",
	StatIds.MOVE_SPEED: "Speed",
	StatIds.ABILITY_HASTE: "Haste",
	StatIds.WILL: "Will",
	StatIds.HP_REGEN: "Regen",
	StatIds.GOLD_PER_PICKUP: "Gold/pickup",
}
const REFRESH_INTERVAL: float = 0.25
## The detailed overlay draws above everything (pause text, menus).
const OVERLAY_LAYER: int = 50

@export var player: Player
## Optional. A node with `stats_context() -> PackedStringArray` (the level,
## safehouse or Nexus), whose lines head the detailed overlay.
@export var context_source: Node

var _grid_labels: Array[Label] = []
var _overlay: PanelContainer
var _run_text: Label
var _stats_text: Label
var _refresh: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_grid()
	_build_overlay()


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var held: bool = Input.is_action_pressed(InputActions.SHOW_STATS)
	if held != _overlay.visible:
		_overlay.visible = held
		_refresh = 0.0
	_refresh -= delta
	if _refresh > 0.0:
		return
	_refresh = REFRESH_INTERVAL
	_update_grid()
	if _overlay.visible:
		_update_overlay()


## Text for one stat's value ("8.0", "25").
static func format_value(stat: StringName, value: float) -> String:
	if stat == StatIds.MOVE_SPEED or stat == StatIds.HP_REGEN:
		return "%.1f" % value
	if stat == StatIds.ABILITY_DURATION:
		return "+%d%%" % roundi(value * 100.0)
	return str(roundi(value))


## The Mirror options brought on this run, as one line.
static func mirror_line() -> String:
	var names: PackedStringArray = PackedStringArray()
	for option: MirrorOption in MetaProgress.chosen_options():
		names.append(option.display_name)
	return "Mirror  %s" % (", ".join(names) if not names.is_empty() else "nothing")


func _value(stat: StringName) -> float:
	return player.stats.get_value(stat) if player.stats.block.has_base(stat) else 0.0


func _build_grid() -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.position -= Vector2(16, 16)
	panel.add_theme_stylebox_override("panel", _panel_style(0.55))
	add_child(panel)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 2)
	panel.add_child(grid)
	for stat: StringName in GRID_STATS:
		var label: Label = Label.new()
		label.add_theme_font_size_override("font_size", 13)
		grid.add_child(label)
		_grid_labels.append(label)
	var hint: Label = Label.new()
	hint.text = "Hold Tab: details"
	hint.add_theme_font_size_override("font_size", 11)
	hint.modulate = Color(1, 1, 1, 0.55)
	grid.add_child(hint)


func _update_grid() -> void:
	for i: int in GRID_STATS.size():
		var stat: StringName = GRID_STATS[i]
		_grid_labels[i].text = "%s  %s" % [GRID_SHORT_NAMES[stat], format_value(stat, _value(stat))]


func _build_overlay() -> void:
	_overlay = PanelContainer.new()
	_overlay.visible = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_overlay.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_overlay.grow_vertical = Control.GROW_DIRECTION_BOTH
	_overlay.add_theme_stylebox_override("panel", _panel_style(0.94))
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = OVERLAY_LAYER
	add_child(layer)
	var full: Control = Control.new()
	full.mouse_filter = Control.MOUSE_FILTER_IGNORE
	full.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(full)
	full.add_child(_overlay)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 40)
	_overlay.add_child(columns)
	_run_text = _overlay_label(columns)
	_stats_text = _overlay_label(columns)


func _overlay_label(parent: Control) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_size_override("font_size", 16)
	label.custom_minimum_size = Vector2(360, 0)
	parent.add_child(label)
	return label


func _update_overlay() -> void:
	var run: PackedStringArray = PackedStringArray()
	if context_source != null and context_source.has_method(&"stats_context"):
		run = context_source.call(&"stats_context")
	var hp: String = (
		"%d / %d" % [roundi(player.health.pool.current), roundi(player.health.pool.maximum)]
	)
	run.append("")
	run.append("HP  %s" % hp)
	run.append("Gold  %d" % player.wallet.gold)
	run.append("Cooldowns  x%.2f" % StatIds.haste_multiplier(_value(StatIds.ABILITY_HASTE)))
	_run_text.text = "\n".join(run)
	var lines: PackedStringArray = PackedStringArray(["Stats", ""])
	for stat: StringName in StatIds.DISPLAY_NAMES:
		var value: float = _value(stat)
		if value == 0.0 and not stat in GRID_STATS:
			continue
		lines.append("%s  %s" % [format_value(stat, value), StatIds.DISPLAY_NAMES[stat]])
	_stats_text.text = "\n".join(lines)


func _panel_style(alpha: float) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.08, alpha)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(12)
	return style
