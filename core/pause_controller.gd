class_name PauseController
extends Node
## Pauses the game.
## - Manual pause: Space / Start / Esc, or the touch pause button. While
##   manually paused, ANY gameplay input unpauses and also takes effect (so you
##   can line up your next move), and pressing pause again just unpauses.
## - Menu pause (e.g. the card pickup screen): only the menu unpauses.
## Must be the LAST child of the level, so it sees input first.

signal paused_changed(paused: bool)

const GROUP: StringName = &"pause_controller"
const STICK_THRESHOLD: float = 0.5
## Actions that never count as "resume playing" input.
const NON_GAMEPLAY_ACTIONS: Array[StringName] = [
	InputActions.PAUSE,
	InputActions.SHOW_STATS,
	InputActions.DEBUG_CYCLE_SCHEME,
	InputActions.DEBUG_SPAWN_ENEMY,
	InputActions.DEBUG_GIVE_LOOT,
	InputActions.DEBUG_CARD_PICKER,
	InputActions.DEBUG_NEXT_LEVEL,
]

var manual_paused: bool = false

var _menu_pauses: int = 0
var _overlay: Label
var _touch_button: Button
## Debug builds: test tuning shown while paused (hunter cap, Shamblers).
var _test_panel: PanelContainer
var _hunter_label: Label
var _shambler_label: Label


static func find(tree: SceneTree) -> PauseController:
	return tree.get_first_node_in_group(GROUP) as PauseController


func _enter_tree() -> void:
	add_to_group(GROUP)
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	get_tree().paused = false
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	_overlay = Label.new()
	_overlay.text = "Paused\nany input resumes"
	_overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_overlay.add_theme_font_size_override("font_size", 36)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false
	layer.add_child(_overlay)
	_touch_button = Button.new()
	_touch_button.text = "II"
	_touch_button.custom_minimum_size = Vector2(64, 64)
	_touch_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_touch_button.position += Vector2(-80, 100)
	_touch_button.visible = false
	_touch_button.pressed.connect(toggle_manual)
	layer.add_child(_touch_button)
	if OS.is_debug_build():
		_build_test_panel(layer)


## Shows the touch pause button only for the touch scheme.
func set_touch_controls_visible(on: bool) -> void:
	_touch_button.visible = on


func toggle_manual() -> void:
	if _menu_pauses > 0:
		return
	manual_paused = not manual_paused
	_apply()


## Enters the normal pause (any input resumes). Used after closing menus,
## so the game doesn't resume the instant you close one.
func enter_manual_pause() -> void:
	manual_paused = true
	_apply()


func push_menu_pause() -> void:
	_menu_pauses += 1
	_apply()


func pop_menu_pause() -> void:
	_menu_pauses = maxi(_menu_pauses - 1, 0)
	_apply()


func is_paused() -> bool:
	return get_tree().paused


func _input(event: InputEvent) -> void:
	if _menu_pauses > 0:
		return
	if event.is_action_pressed(InputActions.PAUSE):
		toggle_manual()
		get_viewport().set_input_as_handled()
		return
	if manual_paused and is_gameplay_press(event) and not _is_on_pause_button(event):
		# Unpause and let this same input carry on to gameplay.
		manual_paused = false
		_apply()


static func is_gameplay_press(event: InputEvent) -> bool:
	# Sticks: only a clear push counts (not drift or a nudge near the deadzone).
	if event is InputEventJoypadMotion:
		return absf((event as InputEventJoypadMotion).axis_value) > STICK_THRESHOLD
	# Only inputs bound to game actions count, so Alt-Tab, Cmd and other
	# unbound keys don't unpause.
	for action: StringName in InputActions.ALL:
		if action in NON_GAMEPLAY_ACTIONS:
			continue
		if event.is_action_pressed(action, false, true):
			return true
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	return false


## True for a click or tap on the pause button or the test panel (those
## don't count as "resume playing").
func _is_on_pause_button(event: InputEvent) -> bool:
	var at: Vector2 = Vector2.INF
	if event is InputEventScreenTouch:
		at = (event as InputEventScreenTouch).position
	elif event is InputEventMouseButton:
		at = (event as InputEventMouseButton).position
	if _touch_button.visible and _touch_button.get_global_rect().has_point(at):
		return true
	return (
		_test_panel != null and _test_panel.visible and _test_panel.get_global_rect().has_point(at)
	)


func _build_test_panel(layer: CanvasLayer) -> void:
	_test_panel = PanelContainer.new()
	_test_panel.visible = false
	_test_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_test_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_test_panel.position += Vector2(16, -16)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.85)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	_test_panel.add_theme_stylebox_override("panel", style)
	layer.add_child(_test_panel)
	var column: VBoxContainer = VBoxContainer.new()
	_test_panel.add_child(column)
	var title: Label = Label.new()
	title.text = "Test tuning"
	title.add_theme_font_size_override("font_size", 13)
	title.modulate = Color(1, 1, 1, 0.7)
	column.add_child(title)
	_hunter_label = _tuning_row(column, _change_hunters)
	_shambler_label = _tuning_row(column, _change_shamblers)
	var builds: HBoxContainer = HBoxContainer.new()
	builds.add_theme_constant_override("separation", 8)
	column.add_child(builds)
	_test_button(builds, "Empty my build", _empty_build)
	_test_button(builds, "Randomise my build", _randomise_build)
	_refresh_test_panel()


func _test_button(parent: Control, text: String, handler: Callable) -> void:
	var button: Button = Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(handler)
	parent.add_child(button)


func _test_player() -> Player:
	return get_tree().get_first_node_in_group(Player.GROUP) as Player


## Clears every deck and backpack slot.
func _empty_build() -> void:
	var player: Player = _test_player()
	if player == null:
		return
	var empty: Array[CardStack] = []
	player.cards.replace_all(empty)


## Fills every rank slot (A-K) with a random card of that rank; backpack empty.
func _randomise_build() -> void:
	var player: Player = _test_player()
	var loot: LootService = LootService.find(get_tree())
	if player == null or loot == null or loot.loot_table == null:
		return
	var library: CardLibrary = loot.loot_table.library
	var stacks: Array[CardStack] = []
	for slot: int in CardInventory.RANK_SLOTS:
		var suit: CardData.Suit = (randi() % 4) as CardData.Suit
		var card: CardData = library.find(suit, slot + 1)
		stacks.append(CardStack.new(card) if card != null else null)
	player.cards.replace_all(stacks)


func _tuning_row(parent: Control, change: Callable) -> Label:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var minus: Button = Button.new()
	minus.text = " − "
	minus.focus_mode = Control.FOCUS_NONE
	minus.pressed.connect(change.bind(-1))
	row.add_child(minus)
	var plus: Button = Button.new()
	plus.text = " + "
	plus.focus_mode = Control.FOCUS_NONE
	plus.pressed.connect(change.bind(1))
	row.add_child(plus)
	var label: Label = Label.new()
	label.add_theme_font_size_override("font_size", 15)
	row.add_child(label)
	return label


func _change_hunters(step: int) -> void:
	ThreatDirector.hunter_cap_offset += step
	_refresh_test_panel()


func _change_shamblers(step: int) -> void:
	ThreatDirector.ambient_offset += step
	_refresh_test_panel()


func _refresh_test_panel() -> void:
	if _test_panel == null:
		return
	var director: ThreatDirector = ThreatDirector.find(get_tree())
	var cap: String = str(director.hunter_cap()) if director != null else "—"
	var shamblers: String = str(director.ambient_target()) if director != null else "—"
	_hunter_label.text = "Hunters on field: %s  (%+d)" % [cap, ThreatDirector.hunter_cap_offset]
	_shambler_label.text = "Shamblers: %s  (%+d)" % [shamblers, ThreatDirector.ambient_offset]


func _apply() -> void:
	var paused: bool = manual_paused or _menu_pauses > 0
	if get_tree().paused != paused:
		get_tree().paused = paused
		paused_changed.emit(paused)
	_overlay.visible = manual_paused and _menu_pauses == 0
	if _test_panel != null:
		_test_panel.visible = _overlay.visible and ThreatDirector.find(get_tree()) != null
		_refresh_test_panel()
