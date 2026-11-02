class_name AbilitySlot
extends RefCounted
## One of the four ability slots: which ability it holds, its cooldown, and the
## execution currently running (if any).

var index: int
var data: AbilityData
var cooldown_remaining: float = 0.0
var execution: AbilityExecution


func _init(p_index: int) -> void:
	index = p_index


func set_ability(ability: AbilityData) -> void:
	cancel()
	data = ability
	cooldown_remaining = 0.0


func is_ready() -> bool:
	return data != null and execution == null and cooldown_remaining <= 0.0


func is_running() -> bool:
	return execution != null


## 1.0 right after the cooldown starts, 0.0 when ready.
func cooldown_fraction() -> float:
	if data == null or data.cooldown <= 0.0:
		return 0.0
	return clampf(cooldown_remaining / data.cooldown, 0.0, 1.0)


func try_cast(context: CastContext) -> bool:
	if not is_ready():
		return false
	var new_execution: AbilityExecution = data.create_execution(context)
	if new_execution == null:
		return false
	execution = new_execution
	execution.start()
	_finish_if_done()
	return true


func tick(delta: float) -> void:
	if execution != null:
		execution.physics_tick(delta)
		_finish_if_done()
	elif cooldown_remaining > 0.0:
		cooldown_remaining = maxf(cooldown_remaining - delta, 0.0)


func update_aim(aim: AimData) -> void:
	if execution != null:
		execution.context.aim = aim
		execution.on_aim_updated()


func cancel() -> void:
	if execution != null:
		execution.cancel()
		_finish_if_done()


func _finish_if_done() -> void:
	if execution != null and execution.finished:
		execution = null
		cooldown_remaining = data.cooldown if data != null else 0.0
