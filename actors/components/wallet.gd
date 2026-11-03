class_name Wallet
extends Node
## The player's gold.

signal changed(gold: int)

var gold: int = 0


func add(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	changed.emit(gold)


func can_afford(amount: int) -> bool:
	return gold >= amount


func spend(amount: int) -> bool:
	if amount > gold:
		return false
	gold -= amount
	changed.emit(gold)
	return true
