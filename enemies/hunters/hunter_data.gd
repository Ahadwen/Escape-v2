class_name HunterData
extends EnemyData
## A hunter: a pursuer with a small kit of abilities, like a champion.
## Always knows where you are; faster than your sustained speed (see
## speed_floor_ratio); its abilities have wind-ups and cooldowns.

## Abilities in priority order: the first one ready and usable is used.
@export var abilities: Array[HunterAbility] = []
## Never slower than the player's sustained speed (base + permanent bonuses,
## not temporary boosts) times this. 0 = no floor.
@export var speed_floor_ratio: float = 1.1
## Further than this from the target, the hunter sprints to catch up ...
@export var catch_up_distance: float = 7.0
## ... at this multiple of its pursuit speed.
@export var catch_up_multiplier: float = 1.5
## Ranged hunters: hold this band of distance (backing off when closer)
## while they can see you; chase to get sight of you otherwise. 0 = melee
## hunter that always closes in.
@export var preferred_range_min: float = 0.0
@export var preferred_range_max: float = 0.0
## Spinning visual (Spinner).
@export var spins: bool = false


func _init() -> void:
	sight_range = 999.0
	lose_interest_range = 0.0
	lifetime_min = 30.0
	lifetime_max = 60.0
	speed_gain_over_life = 0.0


func create_brain() -> EnemyBrain:
	return HunterBrain.new(self)
