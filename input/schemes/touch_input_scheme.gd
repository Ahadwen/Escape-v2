class_name TouchInputScheme
extends InputScheme
## Touch: movement joystick on the left, four ability sticks on the right.
## Ability sticks: drag to aim, release to cast. A tap (no drag) casts with
## no aim, which falls back to the player's facing.
## While no ability stick is held, aim follows the movement stick, so a
## running charge is steered with the movement stick.

## Root of the on-screen touch UI; shown only while this scheme is active.
@export var controls: CanvasLayer
@export var move_stick: TouchJoystick
## One per ability slot, in slot order.
@export var ability_sticks: Array[TouchJoystick] = []

var _aiming_slot: int = NO_SLOT
## Created in code: shown above the ability sticks when something is in range.
var _interact_button: Button
var _ace_cycle_button: Button
var _ace_use_button: Button


func _ready() -> void:
	for slot: int in ability_sticks.size():
		var stick: TouchJoystick = ability_sticks[slot]
		stick.grabbed.connect(_on_ability_grabbed.bind(slot))
		stick.released.connect(_on_ability_released.bind(slot))
	_build_buttons()
	_set_controls_enabled(false)


func _physics_process(_delta: float) -> void:
	if not is_active:
		return
	var origin: Vector3 = _origin()
	_interact_button.visible = Interactable.nearest_in_range(get_tree(), origin) != null
	_update_analog_move(move_stick.output)
	if _aiming_slot != NO_SLOT:
		var aim: AimData = _aim_from_stick(ability_sticks[_aiming_slot].output)
		_emit(AimIntent.new(aim))
		_emit_aim_preview(_aiming_slot, aim)
	else:
		_emit(AimIntent.new(_aim_from_stick(move_stick.output)))


func _on_activated() -> void:
	_set_controls_enabled(true)


func _on_deactivated() -> void:
	_aiming_slot = NO_SLOT
	_set_controls_enabled(false)


func _on_ability_grabbed(slot: int) -> void:
	if _aiming_slot == NO_SLOT:
		_aiming_slot = slot


func _on_ability_released(final_output: Vector2, slot: int) -> void:
	if slot != _aiming_slot:
		return
	_aiming_slot = NO_SLOT
	_end_aim_preview()
	_emit(CastAbilityIntent.new(slot, _aim_from_stick(final_output)))


func _build_buttons() -> void:
	if controls == null:
		return
	_interact_button = _make_button("Interact", Vector2(-300, -560), Vector2(150, 64))
	_interact_button.pressed.connect(func() -> void: _emit(InteractIntent.new()))
	_ace_cycle_button = _make_button("Ace ⟳", Vector2(-620, -150), Vector2(96, 56))
	_ace_cycle_button.pressed.connect(func() -> void: _emit(CycleAceIntent.new(1)))
	_ace_use_button = _make_button("Use Ace", Vector2(-620, -86), Vector2(96, 56))
	_ace_use_button.pressed.connect(func() -> void: _emit(UseAceIntent.new(-1)))


## A button anchored to the bottom-right corner at `offset` from it.
func _make_button(label: String, offset: Vector2, size: Vector2) -> Button:
	var button: Button = Button.new()
	button.text = label
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = offset.x
	button.offset_top = offset.y
	button.offset_right = offset.x + size.x
	button.offset_bottom = offset.y + size.y
	button.focus_mode = Control.FOCUS_NONE
	controls.add_child(button)
	return button


func _set_controls_enabled(enabled: bool) -> void:
	if controls != null:
		controls.visible = enabled
	if move_stick != null:
		move_stick.enabled = enabled
	for stick: TouchJoystick in ability_sticks:
		stick.enabled = enabled
