class_name PCInputScheme
extends InputScheme
## Mouse and keyboard: right-click (or hold) to move, S to stop.
## Abilities on Q/W/E/R arrive in M2.

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


func _process(delta: float) -> void:
	if not is_active or not Input.is_action_pressed(InputActions.MOVE_TO):
		return
	_repath_timer -= delta
	if _repath_timer <= 0.0:
		_repath_timer = repath_interval
		_move_to_cursor()


func _move_to_cursor() -> void:
	var hit: Variant = _screen_to_ground(get_viewport().get_mouse_position())
	if hit is Vector3:
		var point: Vector3 = hit
		_emit(MoveToPointIntent.new(point))
