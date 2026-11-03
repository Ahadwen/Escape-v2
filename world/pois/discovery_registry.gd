class_name DiscoveryRegistry
extends Node
## Remembers discovered points of interest by id, so discoveries survive their
## chunk being unloaded (edge indicators keep pointing to them).

const GROUP: StringName = &"discovery_registry"


class Entry:
	var id: String
	var position: Vector3
	var color: Color
	var label: String
	var show_edge_indicator: bool


var _entries: Dictionary[String, Entry] = {}


static func find(tree: SceneTree) -> DiscoveryRegistry:
	return tree.get_first_node_in_group(GROUP) as DiscoveryRegistry


func _enter_tree() -> void:
	add_to_group(GROUP)


func is_discovered(id: String) -> bool:
	return _entries.has(id)


func remember(
	id: String, position: Vector3, color: Color, label: String, show_edge_indicator: bool
) -> void:
	var entry: Entry = Entry.new()
	entry.id = id
	entry.position = position
	entry.color = color
	entry.label = label
	entry.show_edge_indicator = show_edge_indicator
	_entries[id] = entry


func forget(id: String) -> void:
	_entries.erase(id)


func entries() -> Array[Entry]:
	var list: Array[Entry] = []
	for entry: Entry in _entries.values():
		list.append(entry)
	return list
