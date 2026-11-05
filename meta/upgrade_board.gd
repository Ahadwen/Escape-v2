class_name UpgradeBoard
extends Resource
## The Mirror's full list of upgrades, in display order.

@export var upgrades: Array[UpgradeData] = []


func find(id: StringName) -> UpgradeData:
	for upgrade: UpgradeData in upgrades:
		if upgrade.id == id:
			return upgrade
	return null
