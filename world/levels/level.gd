extends Node3D
## One level: streamed infinite terrain, the threat director, and the player.
## Reaching a safehouse saves the run and moves to the safehouse lobby;
## dying ends the run (a new one starts at level 1).

const RESTART_DELAY_DEATH: float = 2.5
const SAFEHOUSE_DELAY: float = 1.5

## 0 = random seed each run.
@export var fixed_seed: int = 0
@export var card_library: CardLibrary = preload("res://items/data/card_library.tres")

var _finished: bool = false

@onready var _streamer: WorldStreamer = $WorldStreamer
@onready var _input_router: InputRouter = $InputRouter
@onready var _player: Player = $Player
@onready var _director: ThreatDirector = $ThreatDirector
@onready var _move_marker: MoveMarker = $MoveMarker
@onready var _aim_presenter: AimPreviewPresenter = $AimPreviewPresenter
@onready var _ability_bar: AbilityBar = $HUD/AbilityBar
@onready var _message: Label = $HUD/MessageLabel
@onready var _card_bar: CardBar = $HUD/CardBar
@onready var _pickup_screen: CardPickupScreen = $PickupLayer/CardPickupScreen
@onready var _pause: PauseController = $PauseController
@onready var _interact_prompt: InteractPrompt = $HUD/InteractPrompt
@onready var _level_label: Label = $HUD/LevelLabel


func _ready() -> void:
	if not RunState.active:
		RunState.start_new_run(fixed_seed if fixed_seed != 0 else randi())
	var level: int = RunState.level_index
	_level_label.text = "Level %d of %d" % [level + 1, RunState.LEVEL_COUNT]
	_streamer.start(RunState.run_seed, level)
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
	_player.wallet.add(roundi(_player.stats.get_value(StatIds.GOLD_PER_LEVEL)))
	_player.events.level_started.emit()
	# Let the navigation map sync before the director queries it.
	await get_tree().physics_frame
	await get_tree().physics_frame
	_director.start(level)


func _on_scheme_changed(kind: InputRouter.SchemeKind) -> void:
	_ability_bar.set_scheme(kind)
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
	_director.stop(false)
	_aim_presenter.clear_preview()
	_show_message("Caught after %s" % RunInfo.format_time(_director.elapsed))
	RunState.end_run()
	await get_tree().create_timer(RESTART_DELAY_DEATH).timeout
	get_tree().reload_current_scene()


func _show_message(text: String) -> void:
	_message.text = text
	_message.visible = true
