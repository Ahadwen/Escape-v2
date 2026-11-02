class_name AbilityBar
extends Control
## Four ability slots along the bottom of the screen: key, name, cooldown.
## Built in code; greybox styling until the art pass.

const SLOT_SIZE: Vector2 = Vector2(88.0, 72.0)

@export var abilities: AbilityCaster

var _key_labels: Array[Label] = []
var _name_labels: Array[Label] = []
var _cooldown_labels: Array[Label] = []
var _panels: Array[PanelContainer] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row: HBoxContainer = HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	for i: int in AbilityCaster.SLOT_COUNT:
		row.add_child(_build_slot())
	set_scheme(InputRouter.SchemeKind.PC)


static func key_labels_for(kind: InputRouter.SchemeKind) -> PackedStringArray:
	match kind:
		InputRouter.SchemeKind.GAMEPAD:
			return PackedStringArray(["LB", "RB", "LT", "RT"])
		InputRouter.SchemeKind.TOUCH:
			return PackedStringArray(["1", "2", "3", "4"])
	return PackedStringArray(["Q", "W", "E", "R"])


func set_scheme(kind: InputRouter.SchemeKind) -> void:
	var keys: PackedStringArray = key_labels_for(kind)
	for i: int in _key_labels.size():
		_key_labels[i].text = keys[i]


func _process(_delta: float) -> void:
	if abilities == null:
		return
	for i: int in _panels.size():
		var slot: AbilitySlot = abilities.slots[i]
		_name_labels[i].text = slot.data.display_name if slot.data != null else "—"
		if slot.data == null:
			_cooldown_labels[i].text = ""
			_panels[i].modulate = Color(1.0, 1.0, 1.0, 0.35)
		elif slot.is_running():
			_cooldown_labels[i].text = "active"
			_panels[i].modulate = Color(0.7, 1.0, 0.7)
		elif slot.cooldown_remaining > 0.0:
			_cooldown_labels[i].text = "%.1f" % slot.cooldown_remaining
			_panels[i].modulate = Color(0.55, 0.55, 0.55)
		else:
			_cooldown_labels[i].text = ""
			_panels[i].modulate = Color.WHITE


func _build_slot() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = SLOT_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(column)
	var key_label: Label = _make_label(18)
	var name_label: Label = _make_label(11)
	var cooldown_label: Label = _make_label(14)
	column.add_child(key_label)
	column.add_child(name_label)
	column.add_child(cooldown_label)
	_panels.append(panel)
	_key_labels.append(key_label)
	_name_labels.append(name_label)
	_cooldown_labels.append(cooldown_label)
	return panel


func _make_label(font_size: int) -> Label:
	var label: Label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
