class_name NexusMenu
extends Control
## Shared frame for Nexus station screens (Mirror, Armory): a dimmed,
## pausing overlay with a title, a body to fill and a Close button.

signal closed

var _title: Label
var _subtitle: Label
var _body: VBoxContainer
var _close_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.03, 0.02, 0.08, 0.9)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	center.add_child(column)
	_title = make_label("", 30)
	column.add_child(_title)
	_subtitle = make_label("", 16)
	_subtitle.modulate = Color(0.85, 0.8, 1.0)
	column.add_child(_subtitle)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 10)
	column.add_child(_body)
	_close_button = Button.new()
	_close_button.text = "Close"
	_close_button.custom_minimum_size = Vector2(180, 44)
	_close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_close_button.pressed.connect(close)
	column.add_child(_close_button)


func open() -> void:
	visible = true
	var pause: PauseController = PauseController.find(get_tree())
	if pause != null:
		pause.push_menu_pause()
	rebuild()


func close() -> void:
	if not visible:
		return
	visible = false
	var pause: PauseController = PauseController.find(get_tree())
	if pause != null:
		pause.pop_menu_pause()
	closed.emit()


## Override: fill the body.
func rebuild() -> void:
	pass


func clear_body() -> void:
	for child: Node in _body.get_children():
		child.queue_free()


func focus_close() -> void:
	_close_button.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


static func make_label(text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	return label
