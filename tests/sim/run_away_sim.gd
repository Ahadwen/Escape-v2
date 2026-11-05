extends SceneTree
## Balance probe: a bot that "just runs". It keeps a move order on a far point
## in one direction (right-click held), and blinks when stuck (or on cooldown,
## with --blink-on-cooldown). Reports how long it survives and what hit it.
##
##   godot --headless --fixed-fps 60 --path . -s res://tests/sim/run_away_sim.gd \
##       -- [seconds=120] [runs=5] [--blink-on-cooldown]
##
## Safehouses are disabled so the bot keeps running.

const MetaProgressScript := preload("res://meta/meta_progress.gd")
const LEVEL_SCENE: String = "res://world/levels/level.tscn"

var _seconds: float = 120.0
var _runs: int = 5
var _blink_on_cooldown: bool = false
## Restrict the roster to one hunter id (e.g. --only=brute).
var _only: StringName = &""
var _terrain: TerrainProfile
var _trace_timer: float = 0.0
var _hunt: ThreatProfile

var _run: int = 0
## --start-run=N replays from run N (same seeds as a full batch).
var _first_run: int = 0
## Most enemies alive at once this run (0 = the hunt never started).
var _max_enemies: int = 0
var _level: Node
var _player: Player
var _time: float = 0.0
var _heading: Vector3 = Vector3.FORWARD
var _order_timer: float = 0.0
var _stuck_timer: float = 0.0
var _last_position: Vector3
var _hits: Array[String] = []
var _damage: float = 0.0
var _first_hit: float = -1.0
var _died_at: float = -1.0
var _results: PackedStringArray = PackedStringArray()
var _survival: Array[float] = []
var _first_hits: Array[float] = []
var _hit_rates: Array[float] = []


func _initialize() -> void:
	# A clean profile, and never touch the real save.
	MetaProgressScript.saving_enabled = false
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var numbers: Array[String] = []
	for arg: String in args:
		if arg == "--blink-on-cooldown":
			_blink_on_cooldown = true
		elif arg.begins_with("--start-run="):
			_first_run = int(arg.trim_prefix("--start-run="))
			_run = _first_run
		elif arg.begins_with("--only="):
			_only = StringName(arg.trim_prefix("--only="))
		else:
			numbers.append(arg)
	if numbers.size() > 0:
		_seconds = float(numbers[0])
	if numbers.size() > 1:
		_runs = int(numbers[1])
	# Kept as members: if nothing holds them, the cache frees them and the
	# level would load unmodified copies.
	_terrain = load("res://world/streaming/default_terrain.tres")
	_terrain.safehouse_cell_chance = 0.0
	if _only != &"":
		_hunt = load("res://director/data/hunt.tres")
		var hunt: ThreatProfile = _hunt
		var kept: Array[SpawnEntry] = []
		for entry: SpawnEntry in hunt.entries:
			if entry.enemy.id == _only:
				entry.min_threat = 0.0
				entry.max_threat = 0.0
				kept.append(entry)
		hunt.entries = kept
		# The ambient Shamblers only when asked for by name.
		if hunt.ambient_enemy == null or hunt.ambient_enemy.id != _only:
			hunt.ambient_enemy = null
		else:
			hunt.ambient_count = 1
			hunt.ambient_cap = 1
		hunt.max_alive_start = 1
		hunt.max_alive_cap = 1
	_start_run.call_deferred()


func _start_run() -> void:
	seed(1000 + _run * 7919)
	RunState.start_new_run(1000 + _run * 7919)
	_level = (load(LEVEL_SCENE) as PackedScene).instantiate()
	root.add_child(_level)
	_player = _level.get_node("Player") as Player
	var angle: float = randf_range(0.0, TAU)
	_heading = Vector3(cos(angle), 0.0, sin(angle))
	_time = 0.0
	_order_timer = 0.0
	_stuck_timer = 0.0
	_last_position = _player.global_position
	_hits.clear()
	_max_enemies = 0
	_damage = 0.0
	_first_hit = -1.0
	_died_at = -1.0
	_player.health.damaged.connect(_on_damaged)
	_player.died.connect(func() -> void: _died_at = _time)


func _physics_process(delta: float) -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	_time += delta
	_max_enemies = maxi(_max_enemies, get_nodes_in_group(Enemy.GROUP).size())
	if _died_at < 0.0 and _player.health.is_dead:
		_died_at = _time
	if _died_at < 0.0 and _time < _seconds:
		_drive(delta)
		return false
	_finish_run()
	return false


func _trace(delta: float) -> void:
	if not OS.get_cmdline_user_args().has("--trace"):
		return
	_trace_timer -= delta
	if _trace_timer > 0.0:
		return
	_trace_timer = 1.0
	var parts: PackedStringArray = PackedStringArray()
	for node: Node in get_nodes_in_group(Enemy.GROUP):
		var enemy: Enemy = node as Enemy
		var brain: HunterBrain = enemy.brain as HunterBrain
		var action: String = "-"
		if brain != null and brain.current_action != null:
			action = brain.current_action.get_script().get_global_name()
			action = String(brain.current_action.ability.display_name)
		parts.append(
			(
				"%s d=%.1f v=%.1f %s"
				% [
					enemy.data.id,
					enemy.global_position.distance_to(_player.global_position),
					Vector2(enemy.velocity.x, enemy.velocity.z).length(),
					action
				]
			)
		)
	var pv: float = Vector2(_player.velocity.x, _player.velocity.z).length()
	print("t=%.0f player v=%.1f | %s" % [_time, pv, " | ".join(parts)])


func _drive(delta: float) -> void:
	_trace(delta)
	var controller: PlayerController = _player.controller
	_order_timer -= delta
	if _order_timer <= 0.0:
		_order_timer = 0.25
		var goal: Vector3 = _player.global_position + _heading * 40.0
		controller.handle_intent(MoveToPointIntent.new(goal))
	_stuck_timer += delta
	if _stuck_timer >= 0.5:
		var moved: float = _player.global_position.distance_to(_last_position)
		_last_position = _player.global_position
		_stuck_timer = 0.0
		if moved < 1.5:
			_blink()
	if _blink_on_cooldown:
		_blink()


func _blink() -> void:
	_player.controller.handle_intent(CastAbilityIntent.new(0, AimData.from_direction(_heading)))


func _on_damaged(amount: float, event: DamageEvent) -> void:
	_damage += amount
	if _first_hit < 0.0:
		_first_hit = _time
	var who: String = "hazard/burn"
	if event.source is Enemy and (event.source as Enemy).data != null:
		who = String((event.source as Enemy).data.id)
	_hits.append(who)


func _finish_run() -> void:
	var counts: Dictionary = {}
	for who: String in _hits:
		counts[who] = counts.get(who, 0) + 1
	var director: ThreatDirector = _level.get_node("ThreatDirector") as ThreatDirector
	var line: String = (
		"run %d: %s  first hit %s  hits %d  damage %d  threat %.1f  max enemies %d  by %s"
		% [
			_run + 1,
			("DIED at %.1fs" % _died_at) if _died_at >= 0.0 else ("survived %.0fs" % _seconds),
			("%.1fs" % _first_hit) if _first_hit >= 0.0 else "-",
			_hits.size(),
			roundi(_damage),
			director.threat,
			_max_enemies,
			str(counts)
		]
	)
	print(line)
	_results.append(line)
	var lived: float = _died_at if _died_at >= 0.0 else _seconds
	_survival.append(lived)
	_first_hits.append(_first_hit if _first_hit >= 0.0 else lived)
	_hit_rates.append(_hits.size() / maxf(lived, 1.0) * 60.0)
	_level.queue_free()
	_player = null
	_run += 1
	if _run < _first_run + _runs:
		_start_run.call_deferred()
	else:
		_survival.sort()
		var deaths: int = 0
		for t: float in _survival:
			if t < _seconds:
				deaths += 1
		var summary: String = "SUMMARY: %d/%d died within %.0fs" % [deaths, _runs, _seconds]
		summary += " | median survival %.0fs" % _survival[_survival.size() / 2]
		summary += " | mean first hit %.1fs" % _mean(_first_hits)
		summary += " | hits/min %.1f" % _mean(_hit_rates)
		print(summary)
		quit()


static func _mean(values: Array[float]) -> float:
	var total: float = 0.0
	for v: float in values:
		total += v
	return total / maxf(values.size(), 1.0)
