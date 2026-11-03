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


func _is_on_pause_button(event: InputEvent) -> bool:
	if not _touch_button.visible:
		return false
	var at: Vector2 = Vector2.INF
	if event is InputEventScreenTouch:
		at = (event as InputEventScreenTouch).position
	elif event is InputEventMouseButton:
		at = (event as InputEventMouseButton).position
	return _touch_button.get_global_rect().has_point(at)


func _apply() -> void:
	var paused: bool = manual_paused or _menu_pauses > 0
	if get_tree().paused != paused:
		get_tree().paused = paused
		paused_changed.emit(paused)
	_overlay.visible = manual_paused and _menu_pauses == 0
