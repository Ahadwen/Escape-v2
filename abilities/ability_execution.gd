class_name AbilityExecution
extends RefCounted
## One cast of an ability, holding its runtime state. AbilityData resources
## are shared and must stay stateless, so each cast creates one of these.
##
## Instant abilities set finished in start(); timed and sustained ones finish
## later from physics_tick().

## The ability's "active part" is over (e.g. the parry window closed). Fired
## at most once; if an execution never fires it, it fires when it finishes.
signal active_ended

var context: CastContext
var finished: bool = false

var _active_ended: bool = false


func end_active() -> void:
	if not _active_ended:
		_active_ended = true
		active_ended.emit()


func _init(p_context: CastContext) -> void:
	context = p_context


func start() -> void:
	finished = true


func physics_tick(_delta: float) -> void:
	pass


## Called when the caster's aim changes while this execution is running.
func on_aim_updated() -> void:
	pass


func cancel() -> void:
	finished = true
