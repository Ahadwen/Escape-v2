extends "res://tests/framework/test_case.gd"

const AbilitySlotScript := preload("res://abilities/ability_slot.gd")
const AbilityDataScript := preload("res://abilities/ability_data.gd")
const AbilityExecutionScript := preload("res://abilities/ability_execution.gd")
const CastContextScript := preload("res://abilities/cast_context.gd")


## Runs for a fixed time, counting ticks.
class TimedExecution:
	extends "res://abilities/ability_execution.gd"

	var remaining: float
	var ticks: int = 0

	func _init(p_context: CastContext, duration: float) -> void:
		super(p_context)
		remaining = duration

	func start() -> void:
		finished = remaining <= 0.0

	func physics_tick(delta: float) -> void:
		ticks += 1
		remaining -= delta
		if remaining <= 0.0:
			finished = true


class TimedAbility:
	extends "res://abilities/ability_data.gd"

	var duration: float = 0.0

	func create_execution(context: CastContext) -> AbilityExecution:
		return TimedExecution.new(context, duration)


var slot: AbilitySlot


func _ability(cooldown: float, duration: float = 0.0) -> TimedAbility:
	var ability: TimedAbility = TimedAbility.new()
	ability.cooldown = cooldown
	ability.duration = duration
	return ability


func _context() -> CastContext:
	return CastContextScript.new(null, null, null, null)


func before_each() -> void:
	slot = AbilitySlotScript.new(0)


func test_empty_slot_is_not_ready_and_cannot_cast() -> void:
	assert_false(slot.is_ready())
	assert_false(slot.try_cast(_context()))


func test_instant_ability_starts_cooldown_immediately() -> void:
	slot.set_ability(_ability(5.0))
	assert_true(slot.try_cast(_context()))
	assert_false(slot.is_running())
	assert_almost_eq(slot.cooldown_remaining, 5.0)
	assert_false(slot.is_ready())


func test_cannot_cast_during_cooldown() -> void:
	slot.set_ability(_ability(5.0))
	slot.try_cast(_context())
	assert_false(slot.try_cast(_context()))


func test_cooldown_ticks_down_to_ready() -> void:
	slot.set_ability(_ability(1.0))
	slot.try_cast(_context())
	slot.tick(0.6)
	assert_almost_eq(slot.cooldown_remaining, 0.4)
	assert_almost_eq(slot.cooldown_fraction(), 0.4)
	slot.tick(0.6)
	assert_almost_eq(slot.cooldown_remaining, 0.0)
	assert_true(slot.is_ready())


func test_timed_ability_cooldown_starts_when_it_ends() -> void:
	slot.set_ability(_ability(2.0, 1.0))
	assert_true(slot.try_cast(_context()))
	assert_true(slot.is_running())
	slot.tick(0.5)
	assert_true(slot.is_running())
	assert_almost_eq(slot.cooldown_remaining, 0.0)
	slot.tick(0.6)
	assert_false(slot.is_running())
	assert_almost_eq(slot.cooldown_remaining, 2.0)


func test_cannot_cast_while_running() -> void:
	slot.set_ability(_ability(0.0, 1.0))
	slot.try_cast(_context())
	assert_false(slot.try_cast(_context()))


func test_cancel_ends_execution_and_starts_cooldown() -> void:
	slot.set_ability(_ability(3.0, 10.0))
	slot.try_cast(_context())
	slot.cancel()
	assert_false(slot.is_running())
	assert_almost_eq(slot.cooldown_remaining, 3.0)


func test_set_ability_resets_cooldown() -> void:
	slot.set_ability(_ability(5.0))
	slot.try_cast(_context())
	slot.set_ability(_ability(5.0))
	assert_true(slot.is_ready())
