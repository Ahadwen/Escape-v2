class_name AegisEffect
extends CardEffect
## J♥: block a number of hits; each health crystal refreshes one block.

@export var max_blocks: int = 3


func create_instance() -> CardEffectInstance:
	return Instance.new()


class Instance:
	extends CardEffectInstance

	var blocks: int = 0

	func on_equip() -> void:
		blocks = (data as AegisEffect).max_blocks
		intercept_damage(_intercept)
		listen(player.events.crystal_used, _on_crystal)

	func _intercept(_event: DamageEvent, amount: float) -> float:
		if blocks <= 0:
			return amount
		blocks -= 1
		return 0.0

	func _on_crystal() -> void:
		blocks = mini(blocks + 1, (data as AegisEffect).max_blocks)
