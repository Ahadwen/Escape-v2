class_name AbilityCaster
extends Node
## Holds an actor's four ability slots, casts on request and ticks them.

signal ability_cast(slot: int)

const SLOT_COUNT: int = 4

## The node abilities are cast from (the actor's body).
@export var caster: Node3D
@export var movement: ActorMovement
@export var stats: StatsComponent
@export var health: HealthComponent
@export var status: StatusEffectHost

var slots: Array[AbilitySlot] = []

var _aim: AimData = AimData.none()
var _flurry_casts: int = 0
var _flurry_time: float = 0.0
var _flurry_cooldown: float = 0.2


## For the next `seconds`, the next `casts` casts get a flat `cooldown`.
func start_flurry(casts: int, seconds: float, cooldown: float) -> void:
	_flurry_casts = casts
	_flurry_time = seconds
	_flurry_cooldown = cooldown


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
	_refresh_haste()
	var flurry: bool = _flurry_casts > 0 and _flurry_time > 0.0
	if flurry:
		ability_slot.next_cooldown_override = _flurry_cooldown
	var context: CastContext = CastContext.new(
		caster, movement, _stat_block(), _aim, health, status
	)
	if ability_slot.try_cast(context):
		if flurry:
			_flurry_casts -= 1
		ability_cast.emit(slot)
		return true
	ability_slot.next_cooldown_override = -1.0
	return false


func cancel_all() -> void:
	for ability_slot: AbilitySlot in slots:
		ability_slot.cancel()


func update_aim(aim: AimData) -> void:
	_aim = aim if aim != null else AimData.none()
	for ability_slot: AbilitySlot in slots:
		ability_slot.update_aim(_aim)


func _physics_process(delta: float) -> void:
	if _flurry_time > 0.0:
		_flurry_time -= delta
		if _flurry_time <= 0.0:
			_flurry_casts = 0
	_refresh_haste()
	for ability_slot: AbilitySlot in slots:
		ability_slot.tick(delta)


func _refresh_haste() -> void:
	var haste: float = stats.get_value(StatIds.ABILITY_HASTE) if stats != null else 0.0
	var multiplier: float = StatIds.haste_multiplier(haste)
	for ability_slot: AbilitySlot in slots:
		ability_slot.cooldown_multiplier = multiplier


func _stat_block() -> StatBlock:
	return stats.block if stats != null else null
