class_name ChargeExecution
extends AbilityExecution
## TODO(M3): invulnerable while charging; knock back enemies on impact.

var _data: ChargeAbilityData
var _movement: ChargeMovement


func _init(p_context: CastContext, data: ChargeAbilityData) -> void:
	super(p_context)
	_data = data


func start() -> void:
	_movement = ChargeMovement.new(
		context.aim_direction(),
		_data.start_speed,
		_data.max_speed,
		_data.acceleration,
		deg_to_rad(_data.turn_rate_degrees),
		_data.max_duration
	)
	_movement.ended.connect(_on_movement_ended)
	context.movement.start_override(_movement)


func on_aim_updated() -> void:
	if _movement != null:
		_movement.steer_direction = context.aim.direction


func cancel() -> void:
	if _movement != null:
		_movement.cancel()


func _on_movement_ended() -> void:
	finished = true
