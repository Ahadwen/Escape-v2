extends Node3D
## The safehouse: a small, safe, walkable lobby between levels. Walk up to
## the shop counter, the trader, and the exit door to the next level.

var _wildcard_available: bool = true

@onready var _nav_region: NavigationRegion3D = $NavigationRegion3D
@onready var _input_router: InputRouter = $InputRouter
@onready var _player: Player = $Player
@onready var _move_marker: MoveMarker = $MoveMarker
@onready var _aim_presenter: AimPreviewPresenter = $AimPreviewPresenter
@onready var _ability_bar: AbilityBar = $HUD/AbilityBar
@onready var _ace_bar: AceBar = $HUD/AceBar
@onready var _card_bar: CardBar = $HUD/CardBar
@onready var _interact_prompt: InteractPrompt = $HUD/InteractPrompt
@onready var _pause: PauseController = $PauseController
@onready var _shop: ShopScreen = $MenuLayer/ShopScreen
@onready var _trader: TraderScreen = $MenuLayer/TraderScreen
@onready var _level_label: Label = $HUD/LevelLabel
@onready var _shop_counter: Station = $NavigationRegion3D/ShopCounter
@onready var _trader_stall: Station = $NavigationRegion3D/TraderStall
@onready var _exit_door: Station = $NavigationRegion3D/ExitDoor


func _ready() -> void:
	_nav_region.bake_navigation_mesh(false)
	RunState.apply_to(_player)
	_input_router.intent_emitted.connect(_player.controller.handle_intent)
	_input_router.intent_emitted.connect(_on_intent)
	_input_router.aim_preview_changed.connect(_aim_presenter.show_preview)
	_input_router.aim_preview_ended.connect(_aim_presenter.clear_preview)
	_input_router.scheme_changed.connect(_on_scheme_changed)
	_on_scheme_changed(_input_router.active_kind)
	_shop_counter.used.connect(_on_shop)
	_trader_stall.used.connect(func(player: Player) -> void: _trader.open(player))
	_exit_door.used.connect(_on_exit)
	_shop.closed.connect(func() -> void: _wildcard_available = _shop.is_wildcard_available())
	if RunState.is_final_level():
		_exit_door.interactable.prompt = "Escape"
		_level_label.text = "Final safehouse — the way out is through the door"
	else:
		_level_label.text = (
			"Safehouse — next: level %d of %d" % [RunState.level_index + 2, RunState.LEVEL_COUNT]
		)


func _on_scheme_changed(kind: InputRouter.SchemeKind) -> void:
	_ability_bar.set_scheme(kind)
	_ace_bar.set_scheme(kind)
	_card_bar.set_scheme(kind)
	_interact_prompt.set_scheme(kind)
	_pause.set_touch_controls_visible(kind == InputRouter.SchemeKind.TOUCH)


func _on_intent(intent: PlayerIntent) -> void:
	if intent is MoveToPointIntent:
		_move_marker.show_at((intent as MoveToPointIntent).point)


func _on_shop(player: Player) -> void:
	_shop.open(player, _wildcard_available)


func _on_exit(_player_used: Player) -> void:
	RunState.save_from(_player)
	if RunState.is_final_level():
		_level_label.text = "You escaped!"
		RunState.end_run("Escaped! All %d levels survived." % RunState.LEVEL_COUNT)
		await get_tree().create_timer(3.0).timeout
		get_tree().change_scene_to_file(RunState.NEXUS_SCENE)
		return
	RunState.level_index += 1
	get_tree().change_scene_to_file(RunState.LEVEL_SCENE)


## Run details for the stats overlay (hold Tab).
func stats_context() -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	lines.append(
		"Safehouse after level %d of %d" % [RunState.level_index + 1, RunState.LEVEL_COUNT]
	)
	lines.append(StatsHud.mirror_line())
	lines.append("Seed  %d" % RunState.run_seed)
	return lines
