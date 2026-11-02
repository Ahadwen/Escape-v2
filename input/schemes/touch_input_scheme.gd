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


func _ready() -> void:
	for slot: int in ability_sticks.size():
		var stick: TouchJoystick = ability_sticks[slot]
		stick.grabbed.connect(_on_ability_grabbed.bind(slot))
		stick.released.connect(_on_ability_released.bind(slot))
	_set_controls_enabled(false)


func _physics_process(_delta: float) -> void:
	if not is_active:
		return
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


func _set_controls_enabled(enabled: bool) -> void:
	if controls != null:
		controls.visible = enabled
	if move_stick != null:
		move_stick.enabled = enabled
	for stick: TouchJoystick in ability_sticks:
		stick.enabled = enabled
