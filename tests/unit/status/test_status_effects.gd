extends "res://tests/framework/test_case.gd"

const StatusEffectHostScript := preload("res://actors/components/status_effect_host.gd")
const StatsComponentScript := preload("res://actors/components/stats_component.gd")
const SlowEffectScript := preload("res://status/slow_effect.gd")
const StunEffectScript := preload("res://status/stun_effect.gd")
const InvulnerableEffectScript := preload("res://status/invulnerable_effect.gd")

var host: StatusEffectHost
var stats: StatsComponent


func before_each() -> void:
	stats = add_to_tree(StatsComponentScript.new()) as StatsComponent
	stats.block.set_base(StatIds.MOVE_SPEED, 10.0)
	host = add_to_tree(StatusEffectHostScript.new()) as StatusEffectHost
	host.stats = stats


func test_slow_reduces_and_restores_speed() -> void:
	host.apply(SlowEffectScript.new(0.3, 1.0))
	assert_almost_eq(stats.get_value(StatIds.MOVE_SPEED), 7.0)
	host.tick(1.1)
	assert_almost_eq(stats.get_value(StatIds.MOVE_SPEED), 10.0)
	assert_false(host.has_effect(&"slow"))


func test_reapplying_same_id_refreshes_not_stacks() -> void:
	host.apply(SlowEffectScript.new(0.3, 1.0))
	host.apply(SlowEffectScript.new(0.3, 1.0))
	assert_almost_eq(stats.get_value(StatIds.MOVE_SPEED), 7.0)


func test_different_slow_ids_stack_multiplicatively() -> void:
	host.apply(SlowEffectScript.new(0.5, 1.0, &"a"))
	host.apply(SlowEffectScript.new(0.5, 1.0, &"b"))
	assert_almost_eq(stats.get_value(StatIds.MOVE_SPEED), 2.5)


func test_stun_flag_and_expiry() -> void:
	host.apply(StunEffectScript.new(0.5))
	assert_true(host.is_stunned())
	host.tick(0.6)
	assert_false(host.is_stunned())


func test_invulnerable_flag() -> void:
	assert_false(host.is_invulnerable())
	host.apply(InvulnerableEffectScript.new(1.0))
	assert_true(host.is_invulnerable())
	host.remove(&"invulnerable")
	assert_false(host.is_invulnerable())


func test_clear_removes_everything_and_restores_stats() -> void:
	host.apply(SlowEffectScript.new(0.3, 5.0))
	host.apply(StunEffectScript.new(5.0))
	host.clear()
	assert_false(host.is_stunned())
	assert_almost_eq(stats.get_value(StatIds.MOVE_SPEED), 10.0)
