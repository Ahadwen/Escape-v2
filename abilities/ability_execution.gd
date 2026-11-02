class_name AbilityExecution
extends RefCounted
## One cast of an ability, holding its runtime state. AbilityData resources
## are shared and must stay stateless, so each cast creates one of these.
##
## Instant abilities set finished in start(); timed and sustained ones finish
## later from physics_tick().

var context: CastContext
var finished: bool = false


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
