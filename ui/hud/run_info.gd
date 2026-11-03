class_name RunInfo
extends Label
## Elapsed time and current threat, top-right.

@export var director: ThreatDirector


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_theme_font_size_override("font_size", 18)


func _process(_delta: float) -> void:
	if director == null:
		return
	text = "%s\nThreat %.1f" % [format_time(director.elapsed), director.threat]


static func format_time(seconds: float) -> String:
	var total: int = floori(seconds)
	return "%02d:%02d" % [floori(seconds / 60.0), total % 60]
