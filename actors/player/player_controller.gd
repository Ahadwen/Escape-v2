class_name PlayerController
extends Node
## Turns PlayerIntents into actions on the player's components. Knows nothing
## about devices or control schemes.

@export var movement: ActorMovement
@export var abilities: AbilityCaster
@export var cards: CardInventory

## When false (e.g. dead), all intents are ignored.
var enabled: bool = true

## Interactable we're walking to (PC right-click on it), or null.
var _pending_interact: Interactable


func handle_intent(intent: PlayerIntent) -> void:
	if not enabled:
		return
	if intent is MoveToPointIntent:
		_pending_interact = null
		movement.move_to((intent as MoveToPointIntent).point)
	elif intent is MoveDirectionIntent:
		var direction: Vector3 = (intent as MoveDirectionIntent).direction
		if direction != Vector3.ZERO:
			_pending_interact = null
		movement.move_in_direction(direction)
	elif intent is StopIntent:
		_pending_interact = null
		movement.stop()
	elif intent is CastAbilityIntent:
		var cast: CastAbilityIntent = intent as CastAbilityIntent
		abilities.try_cast(cast.slot, cast.aim)
	elif intent is AimIntent:
		abilities.update_aim((intent as AimIntent).aim)
	elif intent is InteractIntent:
		var nearest: Interactable = Interactable.nearest_in_range(
			get_tree(), _player().global_position
		)
		if nearest != null:
			nearest.interact(_player())
	elif intent is MoveToInteractIntent:
		_pending_interact = (intent as MoveToInteractIntent).target
		movement.move_to(_pending_interact.world_position())
	elif intent is UseAceIntent:
		_use_ace((intent as UseAceIntent).ace_index)
	elif intent is CycleAceIntent:
		cards.cycle_selected_ace((intent as CycleAceIntent).step)


func _physics_process(_delta: float) -> void:
	if _pending_interact == null:
		return
	if not is_instance_valid(_pending_interact) or not _pending_interact.enabled:
		_pending_interact = null
		return
	if (
		_pending_interact.flat_distance_to(_player().global_position)
		<= _pending_interact.interact_range
	):
		var target: Interactable = _pending_interact
		_pending_interact = null
		movement.stop()
		target.interact(_player())


func _use_ace(ace_index: int) -> void:
	if cards == null:
		return
	var slot: int = cards.selected_ace_slot if ace_index < 0 else cards.ace_slot_by_index(ace_index)
	if slot != -1:
		cards.use_ace(slot, _player())


func _player() -> Player:
	return get_parent() as Player
