class_name AbilityCaster
extends Node
## Holds an actor's four ability slots, casts on request and ticks them.

signal ability_cast(slot: int)

const SLOT_COUNT: int = 4

## The node abilities are cast from (the actor's body).
@export var caster: Node3D
@export var movement: ActorMovement
@export var stats: StatsComponent

var slots: Array[AbilitySlot] = []

var _aim: AimData = AimData.none()


func _init() -> void:
	for i: int in SLOT_COUNT:
		slots.append(AbilitySlot.new(i))


func set_abilities(abilities: Array[AbilityData]) -> void:
	for i: int in SLOT_COUNT:
		slots[i].set_ability(abilities[i] if i < abilities.size() else null)


func get_ability(slot: int) -> AbilityData:
	return slots[slot].data if slot >= 0 and slot < SLOT_COUNT else null


func try_cast(slot: int, aim: AimData) -> bool:
	if slot < 0 or slot >= SLOT_COUNT:
		return false
	var ability_slot: AbilitySlot = slots[slot]
	if ability_slot.data == null:
		return false
	if ability_slot.data.requires_free_movement and movement != null and movement.has_override():
		return false
	update_aim(aim)
	var context: CastContext = CastContext.new(caster, movement, _stat_block(), _aim)
	if ability_slot.try_cast(context):
		ability_cast.emit(slot)
		return true
	return false


func update_aim(aim: AimData) -> void:
	_aim = aim if aim != null else AimData.none()
	for ability_slot: AbilitySlot in slots:
		ability_slot.update_aim(_aim)


func _physics_process(delta: float) -> void:
	for ability_slot: AbilitySlot in slots:
		ability_slot.tick(delta)


func _stat_block() -> StatBlock:
	return stats.block if stats != null else null
