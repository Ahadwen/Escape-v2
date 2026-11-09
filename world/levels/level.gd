extends Node3D
## One level: streamed infinite terrain, the threat director, and the player.
## Reaching a safehouse saves the run and moves to the safehouse lobby;
## dying ends the run (a new one starts at level 1).

const RESTART_DELAY_DEATH: float = 2.5
const SAFEHOUSE_DELAY: float = 1.5

## 0 = random seed each run.
@export var fixed_seed: int = 0
@export var card_library: CardLibrary = preload("res://items/data/card_library.tres")
@export var zones: ZoneRegistry = preload("res://zones/data/zone_registry.tres")

## This level's blend between the neutral zone and the run's destination.
var theme: LevelTheme

var _finished: bool = false

@onready var _streamer: WorldStreamer = $WorldStreamer
@onready var _input_router: InputRouter = $InputRouter
@onready var _player: Player = $Player
@onready var _director: ThreatDirector = $ThreatDirector
@onready var _move_marker: MoveMarker = $MoveMarker
@onready var _aim_presenter: AimPreviewPresenter = $AimPreviewPresenter
@onready var _ability_bar: AbilityBar = $HUD/AbilityBar
@onready var _ace_bar: AceBar = $HUD/AceBar
@onready var _message: Label = $HUD/MessageLabel
@onready var _card_bar: CardBar = $HUD/CardBar
@onready var _pickup_screen: CardPickupScreen = $PickupLayer/CardPickupScreen
@onready var _pause: PauseController = $PauseController
@onready var _interact_prompt: InteractPrompt = $HUD/InteractPrompt
@onready var _level_label: Label = $HUD/LevelLabel
@onready var _hazards: HazardSpawner = $HazardSpawner
@onready var _environment: WorldEnvironment = $WorldEnvironment
@onready var _sun: DirectionalLight3D = $Sun


func _ready() -> void:
	if not RunState.active:
		RunState.start_new_run(fixed_seed if fixed_seed != 0 else randi())
	var level: int = RunState.level_index
	_level_label.text = "Level %d of %d" % [level + 1, RunState.LEVEL_COUNT]
	# The destination isn't announced: you see it in the levels shifting.
	theme = LevelTheme.new(
		zones.neutral, zones.destination_for_seed(RunState.run_seed), zones.intensity_for(level)
	)
	_apply_atmosphere()
	# Mirror choices that change the run itself (chests, threat pace).
	_streamer.profile = _streamer.profile.duplicate()
	_streamer.profile.chest_chance *= MetaProgress.chest_multiplier()
	_streamer.start(RunState.run_seed, level, theme)
	_director.theme = theme
	_streamer.safehouse_entered.connect(_on_safehouse_entered)
	_streamer.crystal_consumed.connect(_on_crystal_consumed)
	_pickup_screen.set_library(card_library)
	_input_router.intent_emitted.connect(_player.controller.handle_intent)
	_input_router.intent_emitted.connect(_on_intent)
	_input_router.aim_preview_changed.connect(_aim_presenter.show_preview)
	_input_router.aim_preview_ended.connect(_aim_presenter.clear_preview)
	_input_router.scheme_changed.connect(_on_scheme_changed)
	_on_scheme_changed(_input_router.active_kind)
	_player.died.connect(_on_player_died)
	_message.visible = false
	RunState.apply_to(_player)
	_deal_starting_cards()
	_player.wallet.add(roundi(_player.stats.get_value(StatIds.GOLD_PER_LEVEL)))
	_player.events.level_started.emit()
	# Let the navigation map sync before the director queries it.
	await get_tree().physics_frame
	await get_tree().physics_frame
	_director.start(level)
	_director.profile.threat_per_minute *= MetaProgress.threat_multiplier()
	_hazards.start(theme)
	_setup_burning(level)


## Debug builds: F6 skips to the next level, keeping cards and gold.
func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not event.is_action_pressed(InputActions.DEBUG_NEXT_LEVEL):
		return
	if _finished or RunState.is_final_level():
		return
	_finished = true
	RunState.save_from(_player)
	RunState.level_index += 1
	get_tree().reload_current_scene()


func _apply_atmosphere() -> void:
	var neutral: ZoneData = theme.neutral
	var zone: ZoneData = theme.zone
	var env: Environment = _environment.environment.duplicate() as Environment
	env.background_color = theme.blend_color(neutral.background_color, zone.background_color)
	env.ambient_light_color = theme.blend_color(neutral.ambient_color, zone.ambient_color)
	env.ambient_light_energy = theme.blend(neutral.ambient_energy, zone.ambient_energy)
	var fog: float = theme.blend(neutral.fog_density, zone.fog_density)
	env.fog_enabled = fog > 0.0001
	env.fog_light_color = theme.blend_color(neutral.fog_color, zone.fog_color)
	env.fog_density = fog
	_environment.environment = env
	_sun.light_color = theme.blend_color(neutral.sun_color, zone.sun_color)
	_sun.light_energy = theme.blend(neutral.sun_energy, zone.sun_energy)
	var particles: Color = zone.particle_color
	if particles.a > 0.0 and theme.intensity > 0.0:
		particles.a *= theme.intensity
		_player.add_child(_make_particles(particles, theme.intensity))


## Drifting motes around the player (embers, mist). World-space, so they
## stay put as you move through them.
func _make_particles(color: Color, amount_scale: float) -> CPUParticles3D:
	var particles: CPUParticles3D = CPUParticles3D.new()
	particles.amount = maxi(roundi(90 * amount_scale), 8)
	particles.lifetime = 4.0
	particles.local_coords = false
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector3(16.0, 0.5, 12.0)
	particles.position = Vector3(0.0, 0.4, 0.0)
	particles.direction = Vector3.UP
	particles.spread = 25.0
	particles.gravity = Vector3(0.0, 0.5, 0.0)
	particles.initial_velocity_min = 0.2
	particles.initial_velocity_max = 0.8
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.2
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.albedo_color = color
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(0.12, 0.12)
	quad.material = material
	particles.mesh = quad
	return particles


## In zones where hits ignite (Inferno), every hit sets you burning; burn
## ticks don't re-ignite, and health crystals put it out. Ticks get faster
## from level 3.
func _setup_burning(level: int) -> void:
	if not theme.hits_ignite():
		return
	var zone: ZoneData = theme.zone
	var tick: float = zone.burn_tick * (2.0 / 3.0 if level >= 2 else 1.0)
	_player.health.damaged.connect(
		func(_amount: float, event: DamageEvent) -> void:
			if not event.is_burn:
				_player.status.apply(BurnEffect.new(zone.burn_duration, tick, zone.burn_damage))
	)
	_player.events.crystal_used.connect(func() -> void: _player.status.remove(BurnEffect.ID))


func _on_scheme_changed(kind: InputRouter.SchemeKind) -> void:
	_ability_bar.set_scheme(kind)
	_ace_bar.set_scheme(kind)
	_card_bar.set_scheme(kind)
	_interact_prompt.set_scheme(kind)
	_pause.set_touch_controls_visible(kind == InputRouter.SchemeKind.TOUCH)


func _on_crystal_consumed() -> void:
	_player.wallet.add(roundi(_player.stats.get_value(StatIds.GOLD_PER_CRYSTAL)))


func _on_intent(intent: PlayerIntent) -> void:
	if intent is MoveToPointIntent and not _finished:
		_move_marker.show_at((intent as MoveToPointIntent).point)


func _on_safehouse_entered(_who: Player) -> void:
	if _finished:
		return
	_finished = true
	_hazards.stop()
	_player.events.safehouse_entered.emit()
	_player.wallet.add(roundi(_player.stats.get_value(StatIds.SAFEHOUSE_INTEREST)))
	_director.stop(true)
	_player.controller.enabled = false
	_player.abilities.cancel_all()
	_player.movement.stop()
	_aim_presenter.clear_preview()
	_show_message("Safehouse reached in %s" % RunInfo.format_time(_director.elapsed))
	RunState.save_from(_player)
	await get_tree().create_timer(SAFEHOUSE_DELAY).timeout
	get_tree().change_scene_to_file(RunState.SAFEHOUSE_SCENE)


func _on_player_died() -> void:
	if _finished:
		return
	_finished = true
	_hazards.stop()
	_director.stop(false)
	_aim_presenter.clear_preview()
	var time: String = RunInfo.format_time(_director.elapsed)
	_show_message("Caught after %s" % time)
	RunState.end_run(
		"Caught on level %d of %d after %s" % [RunState.level_index + 1, RunState.LEVEL_COUNT, time]
	)
	await get_tree().create_timer(RESTART_DELAY_DEATH).timeout
	get_tree().change_scene_to_file(RunState.NEXUS_SCENE)


func _show_message(text: String) -> void:
	_message.text = text
	_message.visible = true


## Mirror Head Start: cards dealt once, at the start of a run.
func _deal_starting_cards() -> void:
	if RunState.starting_cards_given:
		return
	RunState.starting_cards_given = true
	var kit: MirrorOption = MetaProgress.chosen_of(MirrorOption.Kind.START_CARDS)
	if kit == null:
		return
	var picks: Array[CardData] = []
	for i: int in kit.start_t2:
		picks.append(card_library.cards_of_tier(2).pick_random())
	for i: int in kit.start_t1:
		picks.append(card_library.cards_of_tier(1).pick_random())
	for i: int in kit.start_aces:
		picks.append(card_library.cards_of_tier(0).pick_random())
	for card: CardData in picks:
		var slot: int = _player.cards.first_empty_slot()
		if card != null and slot != -1:
			_player.cards.set_stack(slot, CardStack.new(card))


## Run details for the stats overlay (hold Tab).
func stats_context() -> PackedStringArray:
	var profile: ThreatProfile = _director.profile
	var threat: float = _director.threat
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Level %d of %d" % [RunState.level_index + 1, RunState.LEVEL_COUNT])
	lines.append("Time  %s" % RunInfo.format_time(_director.elapsed))
	lines.append("Threat  %.1f  (+%.2f a minute)" % [threat, profile.level_threat_per_minute()])
	lines.append(
		(
			"Danger  damage x%.2f, speed x%.2f"
			% [profile.damage_multiplier_for(threat), profile.speed_multiplier_for(threat)]
		)
	)
	lines.append(
		"Hunters  %d  (+%d Shamblers)" % [_director.hunter_count(), _director.ambient_count()]
	)
	if theme != null and theme.zone != null:
		lines.append("Zone  %s (%d%%)" % [theme.zone.display_name, roundi(theme.intensity * 100.0)])
	lines.append(StatsHud.mirror_line())
	lines.append("Seed  %d" % RunState.run_seed)
	return lines
