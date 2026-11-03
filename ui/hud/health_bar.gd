class_name HealthBar
extends Control
## HP bar with "current / max" text. Built in code; greybox styling.

@export var health: HealthComponent

var _bar: ProgressBar
var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar = ProgressBar.new()
	_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bar.show_percentage = false
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = Color(0.8, 0.22, 0.2)
	_bar.add_theme_stylebox_override("fill", fill)
	add_child(_bar)
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	if health != null:
		health.pool.changed.connect(_on_changed)
		_on_changed(health.pool.current, health.pool.maximum)


func _on_changed(current: float, maximum: float) -> void:
	_bar.max_value = maxf(maximum, 1.0)
	_bar.value = current
	_label.text = "%d / %d" % [ceili(current), roundi(maximum)]
