class_name DefianceGuard
extends Node
## Mirror Defiance: the first lethal hit leaves the player at a share of max
## HP instead, briefly invulnerable. Once per run (remembered in RunState) or
## once per level (this node is rebuilt with every level's player).

const INVULNERABILITY: float = 1.5

var option: MirrorOption
var player: Player
var _used: bool = false


func setup(p_option: MirrorOption, p_player: Player) -> void:
	option = p_option
	player = p_player
	player.health.interceptors.append(_intercept)


func is_available() -> bool:
	return not _used and (option.per_level or not RunState.defiance_used)


func _intercept(_event: DamageEvent, amount: float) -> float:
	var current: float = player.health.pool.current
	if amount < current or not is_available():
		return amount
	_used = true
	if not option.per_level:
		RunState.defiance_used = true
	player.status.apply(InvulnerableEffect.new(INVULNERABILITY, &"defiance"))
	var target: float = player.health.pool.maximum * option.revive_fraction
	if current > target:
		return current - target
	player.health.heal.call_deferred(target - current)
	return 0.0
