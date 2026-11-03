class_name Chest
extends Node3D
## Opened by interacting. Hands its loot to the LootService (card + gold).

signal consumed

var _opened: bool = false

@onready var interactable: Interactable = $Interactable
@onready var lid: Node3D = $Visual/Lid


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)


func _on_interacted(player: Player) -> void:
	if _opened:
		return
	_opened = true
	interactable.enabled = false
	var tween: Tween = create_tween()
	tween.tween_property(lid, "rotation:x", -1.6, 0.25)
	consumed.emit()
	var loot: LootService = LootService.find(get_tree())
	if loot != null:
		loot.open_chest(player)
