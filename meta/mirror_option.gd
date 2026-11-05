class_name MirrorOption
extends Resource
## One choice in a Mirror row. Most are stat bonuses; the rest hook into the
## run: a revive, starting cards, or the run itself (threat pace, chests).

enum Kind { STAT, DEFIANCE, START_CARDS, RUN }

@export var id: StringName
@export var display_name: String
@export_multiline var description: String = ""
@export var kind: Kind = Kind.STAT

@export_group("Stat")
@export var stat: StringName
@export var type: StatModifier.Type = StatModifier.Type.FLAT
@export var value: float = 0.0

@export_group("Defiance")
## Once per level (true) or once per run (false).
@export var per_level: bool = false
## Fraction of max HP you're left on after the revive.
@export_range(0.0, 1.0) var revive_fraction: float = 0.5

@export_group("Start cards")
@export var start_t2: int = 0
@export var start_t1: int = 0
@export var start_aces: int = 0

@export_group("Run")
## Multiplies how fast threat rises.
@export var threat_multiplier: float = 1.0
## Multiplies how often chests appear.
@export var chest_multiplier: float = 1.0


func modifier() -> StatModifier:
	return StatModifier.new(stat, type, value, StringName("meta:%s" % id))
