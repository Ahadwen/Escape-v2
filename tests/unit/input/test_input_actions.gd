extends "res://tests/framework/test_case.gd"

const InputActionsScript := preload("res://input/input_actions.gd")


func test_every_action_is_registered_in_input_map() -> void:
	for action: StringName in InputActionsScript.ALL:
		assert_true(InputMap.has_action(action), "InputMap is missing action '%s'" % action)


func test_every_action_has_at_least_one_binding() -> void:
	for action: StringName in InputActionsScript.ALL:
		if not InputMap.has_action(action):
			continue
		assert_false(
			InputMap.action_get_events(action).is_empty(), "Action '%s' has no bindings" % action
		)


func test_action_names_are_unique() -> void:
	var seen: Dictionary = {}
	for action: StringName in InputActionsScript.ALL:
		assert_false(seen.has(action), "Duplicate action '%s'" % action)
		seen[action] = true


func test_ability_slots_map_to_ability_actions() -> void:
	assert_eq(InputActionsScript.ABILITIES.size(), InputActionsScript.ABILITY_SLOT_COUNT)
	assert_eq(InputActionsScript.ability(0), InputActionsScript.ABILITY_1)
	assert_eq(InputActionsScript.ability(3), InputActionsScript.ABILITY_4)


func test_ability_actions_are_in_full_list() -> void:
	for action: StringName in InputActionsScript.ABILITIES:
		assert_true(action in InputActionsScript.ALL, "'%s' missing from ALL" % action)
