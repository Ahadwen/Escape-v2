class_name HunterAbility
extends Resource
## One ability in a hunter's kit: when it can be used (range, line of sight,
## cooldown) and the action that performs it.

@export var display_name: String = ""
@export var cooldown: float = 5.0
## Cooldown when the hunter arrives (so it doesn't open with everything).
@export var initial_cooldown: float = 1.5
@export var min_range: float = 0.0
@export var max_range: float = 10.0
## Needs a clear line to the target (walls block it).
@export var needs_line_of_sight: bool = false
## Show a ground warning during the wind-up. Light attacks don't need one:
## the hunter's body flashing is their tell.
@export var show_warning: bool = true
## May cut off whatever the hunter is doing (e.g. the Artillerist's escape).
@export var interrupts: bool = false


func can_use(brain: HunterBrain) -> bool:
	if brain.target == null:
		return false
	var distance: float = brain.distance_to_target()
	if distance < min_range or distance > max_range:
		return false
	return not needs_line_of_sight or brain.has_line_of_sight_to_target()


## Override: create the action that performs this ability.
func create_action(brain: HunterBrain) -> HunterAction:
	return HunterAction.new(brain)
