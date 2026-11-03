class_name GamepadInputScheme
extends InputScheme
## Gamepad: left stick moves, right stick aims, LB/RB/LT/RT cast, A/Cross
## interacts, D-pad left/right selects an ace and B/Circle uses it.
## With the right stick centred, aim falls back to the left stick (so a charge
## can be steered with the movement stick), then to the player's facing.

## Right-stick deflection needed to count as aiming.
@export var aim_threshold: float = 0.3

var _previewing: bool = false


func _physics_process(_delta: float) -> void:
	if not is_active:
		return
	var move_stick: Vector2 = Input.get_vector(
		InputActions.MOVE_LEFT,
		InputActions.MOVE_RIGHT,
		InputActions.MOVE_UP,
		InputActions.MOVE_DOWN
	)
	var aim_stick: Vector2 = Input.get_vector(
		InputActions.AIM_LEFT, InputActions.AIM_RIGHT, InputActions.AIM_UP, InputActions.AIM_DOWN
	)
	_update_analog_move(move_stick)

	var aiming: bool = aim_stick.length() >= aim_threshold
	var aim: AimData = _aim_from_stick(aim_stick if aiming else move_stick)
	_emit(AimIntent.new(aim))
	_update_preview(aiming, aim)

	for slot: int in InputActions.ABILITY_SLOT_COUNT:
		if Input.is_action_just_pressed(InputActions.ability(slot)):
			_emit(CastAbilityIntent.new(slot, aim))
	if Input.is_action_just_pressed(InputActions.INTERACT):
		_emit(InteractIntent.new())
	if Input.is_action_just_pressed(InputActions.ACE_NEXT):
		_emit(CycleAceIntent.new(1))
	if Input.is_action_just_pressed(InputActions.ACE_PREVIOUS):
		_emit(CycleAceIntent.new(-1))
	if Input.is_action_just_pressed(InputActions.USE_SELECTED_ACE):
		_emit(UseAceIntent.new(-1))


func _on_deactivated() -> void:
	_previewing = false


func _update_preview(aiming: bool, aim: AimData) -> void:
	if aiming:
		_previewing = true
		_emit_aim_preview(NO_SLOT, aim)
	elif _previewing:
		_previewing = false
		_end_aim_preview()
