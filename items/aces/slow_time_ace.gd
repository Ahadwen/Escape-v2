class_name SlowTimeAce
extends AceEffect
## A♠: every enemy and enemy projectile slows down for a few seconds.

@export_range(0.0, 0.95) var slow: float = 0.3
@export var duration: float = 3.0


func use(_player: Player) -> bool:
	EnemyTime.slow(1.0 - slow, duration)
	return true
