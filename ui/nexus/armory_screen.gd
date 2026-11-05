class_name ArmoryScreen
extends NexusMenu
## The Armory: choose who to play. Locked characters (and places for ones
## still to come) are shown but can't be picked yet.

const CARD_SIZE: Vector2 = Vector2(190, 150)


func rebuild() -> void:
	_title.text = "The Armory"
	var chosen: CharacterData = MetaProgress.selected_character()
	_subtitle.text = "Playing as %s" % (chosen.display_name if chosen != null else "—")
	clear_body()
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	_body.add_child(row)
	var roster: CharacterRoster = MetaProgress.roster()
	var focus: Button = null
	for character: CharacterData in roster.characters:
		var card: Button = _character_card(character, chosen)
		row.add_child(card)
		if focus == null or character == chosen:
			focus = card
	for i: int in roster.placeholder_slots:
		row.add_child(_placeholder_card())
	if focus != null:
		focus.grab_focus.call_deferred()


func _character_card(character: CharacterData, chosen: CharacterData) -> Button:
	var card: Button = Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var unlocked: bool = MetaProgress.is_unlocked(character.id)
	var abilities: PackedStringArray = PackedStringArray()
	for ability: AbilityData in character.get_abilities():
		if ability != null:
			abilities.append(ability.display_name)
	card.text = "%s\n\n%s" % [character.display_name, "\n".join(abilities)]
	if not unlocked:
		card.text = "%s\n\nLocked" % character.display_name
		card.disabled = true
	elif character == chosen:
		card.text += "\n\n✓ Selected"
	card.pressed.connect(_on_pick.bind(character))
	return card


func _placeholder_card() -> Button:
	var card: Button = Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.text = "???\n\nComing later"
	card.disabled = true
	card.focus_mode = Control.FOCUS_NONE
	return card


func _on_pick(character: CharacterData) -> void:
	MetaProgress.select_character(character.id)
	rebuild()
