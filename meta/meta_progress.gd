class_name MetaProgress
extends RefCounted
## Progress kept between runs and between game sessions: what you bring from
## the Mirror (one option per row, or none), unlocked characters and the
## chosen one, and Reagents (not earned yet). Saved to user://meta.json
## whenever it changes; loaded on first use.

const SAVE_PATH: String = "user://meta.json"
const BOARD_PATH: String = "res://meta/data/mirror.tres"
const ROSTER_PATH: String = "res://characters/roster.tres"

static var reagents: int = 0
## Mirror row id -> chosen option id (as Strings).
static var choices: Dictionary = {}
static var unlocked: Array[StringName] = []
static var selected: StringName = &""
## Off in tests and sims, so they never touch the real save.
static var saving_enabled: bool = true

static var _loaded: bool = false


static func board() -> MirrorBoard:
	return load(BOARD_PATH) as MirrorBoard


static func roster() -> CharacterRoster:
	return load(ROSTER_PATH) as CharacterRoster


## The option chosen in a Mirror row ("" = none).
static func choice(row_id: StringName) -> StringName:
	ensure_loaded()
	return StringName(str(choices.get(String(row_id), "")))


## Chooses an option in a row; choosing the current one again clears it.
static func choose(row_id: StringName, option_id: StringName) -> void:
	ensure_loaded()
	if choice(row_id) == option_id:
		choices.erase(String(row_id))
	else:
		choices[String(row_id)] = String(option_id)
	save()


## Every option currently brought from the Mirror.
static func chosen_options() -> Array[MirrorOption]:
	var picked: Array[MirrorOption] = []
	var mirror: MirrorBoard = board()
	if mirror == null:
		return picked
	for row: MirrorRow in mirror.rows:
		var option: MirrorOption = row.option(choice(row.id))
		if option != null:
			picked.append(option)
	return picked


## The first chosen option of a kind, or null.
static func chosen_of(kind: MirrorOption.Kind) -> MirrorOption:
	for option: MirrorOption in chosen_options():
		if option.kind == kind:
			return option
	return null


## How much faster threat rises with the chosen options (1 = normal).
static func threat_multiplier() -> float:
	var total: float = 1.0
	for option: MirrorOption in chosen_options():
		total *= option.threat_multiplier
	return total


## How much more often chests appear with the chosen options (1 = normal).
static func chest_multiplier() -> float:
	var total: float = 1.0
	for option: MirrorOption in chosen_options():
		total *= option.chest_multiplier
	return total


static func add_reagents(amount: int) -> void:
	ensure_loaded()
	reagents = maxi(reagents + amount, 0)
	save()


static func is_unlocked(id: StringName) -> bool:
	ensure_loaded()
	return id in unlocked


static func select_character(id: StringName) -> void:
	ensure_loaded()
	if is_unlocked(id):
		selected = id
		save()


## The character to play (the chosen one, else the first unlocked).
static func selected_character() -> CharacterData:
	ensure_loaded()
	var list: CharacterRoster = roster()
	var chosen: CharacterData = list.find(selected) if list != null else null
	if chosen == null and list != null and not list.characters.is_empty():
		chosen = list.characters[0]
	return chosen


## Puts the chosen Mirror stat bonuses on a stat block (replacing any
## earlier ones, so it can be re-applied after the choices change).
static func apply_to(block: StatBlock) -> void:
	ensure_loaded()
	var mirror: MirrorBoard = board()
	if mirror == null:
		return
	for row: MirrorRow in mirror.rows:
		for option: MirrorOption in [row.option_a, row.option_b]:
			if option != null and option.kind == MirrorOption.Kind.STAT:
				block.remove_modifiers_from(StringName("meta:%s" % option.id))
	for option: MirrorOption in chosen_options():
		if option.kind == MirrorOption.Kind.STAT:
			block.add_modifier(option.modifier())


static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	reset()
	if not saving_enabled or not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	if data is Dictionary:
		_read(data as Dictionary)


## Back to a fresh profile (in memory; doesn't save).
static func reset() -> void:
	reagents = 0
	choices = {}
	selected = &""
	unlocked.clear()
	var list: CharacterRoster = roster()
	if list != null:
		unlocked.append_array(list.starting_unlocks)


static func save() -> void:
	if not saving_enabled:
		return
	var data: Dictionary = {
		"version": 2,
		"reagents": reagents,
		"choices": choices,
		"unlocked": unlocked.map(func(id: StringName) -> String: return String(id)),
		"selected": String(selected),
	}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))


static func _read(data: Dictionary) -> void:
	reagents = int(data.get("reagents", 0))
	var saved_choices: Variant = data.get("choices", {})
	if saved_choices is Dictionary:
		choices = (saved_choices as Dictionary).duplicate()
	var saved_unlocks: Variant = data.get("unlocked", [])
	if saved_unlocks is Array:
		for id: Variant in saved_unlocks:
			if not StringName(str(id)) in unlocked:
				unlocked.append(StringName(str(id)))
	selected = StringName(str(data.get("selected", "")))
