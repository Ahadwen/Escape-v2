class_name DashExecution
extends AbilityExecution

## Emitted when the dash ends, with the landing position. (M3: shockwave.)
signal landed(position: Vector3)

var _data: DashAbilityData
var _movement: DashMovement


func _init(p_context: CastContext, data: DashAbilityData) -> void:
	super(p_context)
	_data = data


func start() -> void:
	_movement = DashMovement.new(
		context.aim_direction(), _data.get_range(context.stats), _data.dash_speed
	)
	_movement.ended.connect(_on_movement_ended)
	context.movement.start_override(_movement)


func cancel() -> void:
	if _movement != null:
		_movement.cancel()


func _on_movement_ended() -> void:
	landed.emit(context.origin())
	finished = true
