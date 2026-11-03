class_name PCInputScheme
extends InputScheme
## Mouse and keyboard: right-click (or hold) to move, S to stop, Q/W/E/R to
## cast toward the cursor (quick cast), F to interact, 1-4 to use aces.
## Right-clicking near an interactable walks there and interacts on arrival.

## How close to an interactable a right-click must land to target it.
const INTERACT_CLICK_RADIUS: float = 1.6

## While move is held, re-issue the move order toward the cursor this often.
@export var repath_interval: float = 0.1

var _repath_timer: float = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event.is_action_pressed(InputActions.MOVE_TO):
		if not _interact_at_cursor():
			_move_to_cursor()
		_repath_timer = repath_interval
	elif event.is_action_pressed(InputActions.STOP):
		_emit(StopIntent.new())
	elif event.is_action_pressed(InputActions.INTERACT):
		_emit(InteractIntent.new())
	elif _handle_ace_keys(event):
		pass
	else:
		for slot: int in InputActions.ABILITY_SLOT_COUNT:
			if event.is_action_pressed(InputActions.ability(slot)):
				_emit(CastAbilityIntent.new(slot, _cursor_aim()))
				break


func _process(delta: float) -> void:
	if not is_active or not Input.is_action_pressed(InputActions.MOVE_TO):
		return
	_repath_timer -= delta
	if _repath_timer <= 0.0:
		_repath_timer = repath_interval
		_move_to_cursor()


func _physics_process(_delta: float) -> void:
	if is_active:
		_emit(AimIntent.new(_cursor_aim()))


func _handle_ace_keys(event: InputEvent) -> bool:
	for i: int in InputActions.ACE_KEY_COUNT:
		if event.is_action_pressed(InputActions.USE_ACE_KEYS[i]):
			_emit(UseAceIntent.new(i))
			return true
	return false


## Right-click on an interactable: walk there and interact. Returns true if
## the click hit one.
func _interact_at_cursor() -> bool:
	var hit: Variant = _screen_to_ground(get_viewport().get_mouse_position())
	if not hit is Vector3:
		return false
	var point: Vector3 = hit
	var target: Interactable = Interactable.nearest_to_point(
		get_tree(), point, INTERACT_CLICK_RADIUS
	)
	if target == null:
		return false
	_emit(MoveToInteractIntent.new(target))
	return true


func _cursor_aim() -> AimData:
	return _aim_at_screen_position(get_viewport().get_mouse_position())


func _move_to_cursor() -> void:
	var hit: Variant = _screen_to_ground(get_viewport().get_mouse_position())
	if hit is Vector3:
		var point: Vector3 = hit
		_emit(MoveToPointIntent.new(point))
