class_name MetaProgress
extends RefCounted
## Progress kept between runs and between game sessions: Reagents, Mirror
## upgrade ranks, unlocked characters and the chosen one. Saved to
## user://meta.json whenever it changes; loaded on first use.

const SAVE_PATH: String = "user://meta.json"
const BOARD_PATH: String = "res://meta/data/mirror.tres"
const ROSTER_PATH: String = "res://characters/roster.tres"

static var reagents: int = 0
static var ranks: Dictionary = {}
static var unlocked: Array[StringName] = []
static var selected: StringName = &""
## Off in tests and sims, so they never touch the real save.
static var saving_enabled: bool = true

static var _loaded: bool = false


static func board() -> UpgradeBoard:
	return load(BOARD_PATH) as UpgradeBoard


static func roster() -> CharacterRoster:
	return load(ROSTER_PATH) as CharacterRoster


static func rank_of(id: StringName) -> int:
	ensure_loaded()
	return int(ranks.get(String(id), 0))


## Buys the next rank of an upgrade. Returns true if bought.
static func buy_rank(upgrade: UpgradeData) -> bool:
	ensure_loaded()
	var cost: int = upgrade.cost_after(rank_of(upgrade.id))
	if cost < 0 or reagents < cost:
		return false
	reagents -= cost
	ranks[String(upgrade.id)] = rank_of(upgrade.id) + 1
	save()
	return true


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


## Puts every owned Mirror upgrade on a stat block (replacing earlier ones).
static func apply_to(block: StatBlock) -> void:
	ensure_loaded()
	var upgrades: UpgradeBoard = board()
	if upgrades == null:
		return
	for upgrade: UpgradeData in upgrades.upgrades:
		block.remove_modifiers_from(StringName("meta:%s" % upgrade.id))
		var rank: int = rank_of(upgrade.id)
		if rank > 0:
			block.add_modifier(upgrade.modifier(rank))


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
	ranks = {}
	selected = &""
	unlocked.clear()
	var list: CharacterRoster = roster()
	if list != null:
		unlocked.append_array(list.starting_unlocks)


static func save() -> void:
	if not saving_enabled:
		return
	var data: Dictionary = {
		"version": 1,
		"reagents": reagents,
		"ranks": ranks,
		"unlocked": unlocked.map(func(id: StringName) -> String: return String(id)),
		"selected": String(selected),
	}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))


static func _read(data: Dictionary) -> void:
	reagents = int(data.get("reagents", 0))
	var saved_ranks: Variant = data.get("ranks", {})
	if saved_ranks is Dictionary:
		ranks = (saved_ranks as Dictionary).duplicate()
	var saved_unlocks: Variant = data.get("unlocked", [])
	if saved_unlocks is Array:
		for id: Variant in saved_unlocks:
			if not StringName(str(id)) in unlocked:
				unlocked.append(StringName(str(id)))
	selected = StringName(str(data.get("selected", "")))
