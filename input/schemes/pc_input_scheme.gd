class_name PCInputScheme
extends InputScheme
## Mouse and keyboard: right-click (or hold) to move, S to stop, Q/W/E/R to
## cast toward the cursor (quick cast).

## While move is held, re-issue the move order toward the cursor this often.
@export var repath_interval: float = 0.1

var _repath_timer: float = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event.is_action_pressed(InputActions.MOVE_TO):
		_move_to_cursor()
		_repath_timer = repath_interval
	elif event.is_action_pressed(InputActions.STOP):
		_emit(StopIntent.new())
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


func _cursor_aim() -> AimData:
	return _aim_at_screen_position(get_viewport().get_mouse_position())


func _move_to_cursor() -> void:
	var hit: Variant = _screen_to_ground(get_viewport().get_mouse_position())
	if hit is Vector3:
		var point: Vector3 = hit
		_emit(MoveToPointIntent.new(point))
