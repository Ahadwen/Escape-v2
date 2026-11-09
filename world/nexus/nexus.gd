extends Node3D
## The Nexus: the hub between runs. Every run starts and ends here. Walk
## into the portal to start a run, choose who to play at the Armory, and buy
## at the Mirror what to bring (one choice per row).

@onready var _nav_region: NavigationRegion3D = $NavigationRegion3D
@onready var _input_router: InputRouter = $InputRouter
@onready var _player: Player = $Player
@onready var _move_marker: MoveMarker = $MoveMarker
@onready var _aim_presenter: AimPreviewPresenter = $AimPreviewPresenter
@onready var _ability_bar: AbilityBar = $HUD/AbilityBar
@onready var _interact_prompt: InteractPrompt = $HUD/InteractPrompt
@onready var _pause: PauseController = $PauseController
@onready var _title: Label = $HUD/TitleLabel
@onready var _status: Label = $HUD/StatusLabel
@onready var _portal: Station = $NavigationRegion3D/Portal
@onready var _armory: Station = $NavigationRegion3D/Armory
@onready var _mirror: Station = $NavigationRegion3D/Mirror
@onready var _armory_screen: ArmoryScreen = $MenuLayer/ArmoryScreen
@onready var _mirror_screen: MirrorScreen = $MenuLayer/MirrorScreen


func _ready() -> void:
	# A run never continues through the Nexus.
	RunState.end_run()
	_nav_region.bake_navigation_mesh(false)
	_input_router.intent_emitted.connect(_player.controller.handle_intent)
	_input_router.intent_emitted.connect(_on_intent)
	_input_router.aim_preview_changed.connect(_aim_presenter.show_preview)
	_input_router.aim_preview_ended.connect(_aim_presenter.clear_preview)
	_input_router.scheme_changed.connect(_on_scheme_changed)
	_on_scheme_changed(_input_router.active_kind)
	_portal.used.connect(_on_portal)
	_armory.used.connect(func(_who: Player) -> void: _armory_screen.open())
	_mirror.used.connect(func(_who: Player) -> void: _mirror_screen.open())
	_armory_screen.closed.connect(_on_armory_closed)
	_mirror_screen.closed.connect(_on_mirror_closed)
	_title.text = "The Nexus"
	if RunState.last_result.is_empty():
		_status.text = "Walk into the portal to start a run."
	else:
		_status.text = "Last run: %s" % RunState.last_result


func _on_scheme_changed(kind: InputRouter.SchemeKind) -> void:
	_ability_bar.set_scheme(kind)
	_interact_prompt.set_scheme(kind)
	_pause.set_touch_controls_visible(kind == InputRouter.SchemeKind.TOUCH)


func _on_intent(intent: PlayerIntent) -> void:
	if intent is MoveToPointIntent:
		_move_marker.show_at((intent as MoveToPointIntent).point)


func _on_portal(_player_used: Player) -> void:
	RunState.start_new_run(randi())
	_status.text = "Entering..."
	get_tree().change_scene_to_file(RunState.LEVEL_SCENE)


## New upgrades show up straight away on the Nexus player.
func _on_mirror_closed() -> void:
	MetaProgress.apply_to(_player.stats.block)
	_player.health.refresh_max(true)


## A different character means a different player: rebuild the room.
func _on_armory_closed() -> void:
	if MetaProgress.selected_character() != _player.character:
		get_tree().reload_current_scene()


## Details for the stats overlay (hold Tab).
func stats_context() -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray(["The Nexus"])
	lines.append("Playing as  %s" % _player.character.display_name)
	lines.append(StatsHud.mirror_line())
	if not RunState.last_result.is_empty():
		lines.append("Last run  %s" % RunState.last_result)
	return lines
