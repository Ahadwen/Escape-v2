class_name DamageResolver
extends RefCounted
## Turns incoming damage into HP lost. Armour mitigates physical damage and
## elemental resistance mitigates elemental damage, with diminishing returns:
## 100 resistance halves damage, 200 thirds it; negative resistance amplifies.


static func mitigate(amount: float, resistance: float) -> float:
	if resistance >= 0.0:
		return amount * 100.0 / (100.0 + resistance)
	return amount * (2.0 - 100.0 / (100.0 - resistance))


static func resolve(event: DamageEvent, stats: StatBlock) -> float:
	if stats == null:
		return event.amount
	var stat: StringName = (
		StatIds.ARMOUR
		if event.type == DamageEvent.DamageType.PHYSICAL
		else StatIds.ELEMENTAL_RESIST
	)
	return mitigate(event.amount, stats.get_value(stat))
