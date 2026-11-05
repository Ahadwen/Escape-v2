class_name MirrorScreen
extends NexusMenu
## The Mirror: choose what to bring on your runs. Each row has two
## alternatives; bring one, or neither. (Everything is unlocked for now.)

const OPTION_SIZE: Vector2 = Vector2(330, 74)
const SELECTED: Color = Color(1.0, 0.82, 0.3)


func rebuild() -> void:
	_title.text = "The Mirror"
	_subtitle.text = "Choose what you bring. Click a choice again to leave it behind."
	clear_body()
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	_body.add_child(grid)
	var first: Button = null
	for row: MirrorRow in MetaProgress.board().rows:
		var label: Label = make_label(row.display_name, 18)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.custom_minimum_size = Vector2(120, 0)
		grid.add_child(label)
		for option: MirrorOption in [row.option_a, row.option_b]:
			var button: Button = _option_button(row, option)
			grid.add_child(button)
			if first == null:
				first = button
	if first != null:
		first.grab_focus.call_deferred()


func _option_button(row: MirrorRow, option: MirrorOption) -> Button:
	var chosen: bool = MetaProgress.choice(row.id) == option.id
	var button: Button = Button.new()
	button.custom_minimum_size = OPTION_SIZE
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.text = "%s%s\n%s" % ["✓ " if chosen else "", option.display_name, option.description]
	button.add_theme_font_size_override("font_size", 14)
	var fill: Color = Color(0.16, 0.13, 0.24) if chosen else Color(0.1, 0.09, 0.14)
	button.add_theme_stylebox_override(
		"normal", _style(fill, SELECTED if chosen else Color(0, 0, 0, 0))
	)
	button.add_theme_stylebox_override(
		"hover", _style(fill.lightened(0.1), SELECTED if chosen else Color(1, 1, 1, 0.2))
	)
	button.add_theme_stylebox_override("pressed", _style(fill.lightened(0.2), SELECTED))
	button.add_theme_stylebox_override("focus", _style(Color(0, 0, 0, 0), Color.WHITE))
	if not chosen:
		button.modulate = Color(1, 1, 1, 0.75)
	button.pressed.connect(_on_choose.bind(row, option))
	return button


func _style(fill: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2 if border.a > 0.0 else 0)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	return style


func _on_choose(row: MirrorRow, option: MirrorOption) -> void:
	MetaProgress.choose(row.id, option.id)
	rebuild()
