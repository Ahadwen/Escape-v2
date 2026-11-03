class_name GoldEconomy
extends Resource
## Every gold amount in one place, as multiples of a base unit, so the whole
## economy can be rescaled at once. (A proper economy design is still to do.)

@export var base_unit: int = 5

@export_group("Sources (in base units)")
@export var card_pickup: float = 2.0
@export var chest_bonus_min: float = 0.0
@export var chest_bonus_max: float = 2.0


func units(amount: float) -> int:
	return roundi(amount * base_unit)


func card_pickup_gold(bonus_flat: float) -> int:
	return units(card_pickup) + roundi(bonus_flat)


func chest_bonus_gold() -> int:
	return units(randf_range(chest_bonus_min, chest_bonus_max))
