class_name DeckLayout
extends RefCounted
## Lays out the 16 card slots like V1's deck panel: the Ace slot on the
## left (full height), ranks 2-K in a 2x6 grid in the middle, and the
## 3-slot backpack stacked on the right.


## Builds the layout into `parent`. `make_cell(slot) -> Control` creates the
## cell for each slot index (see CardInventory). Returns the cells by slot.
static func build(parent: Control, make_cell: Callable, gap: int = 6) -> Array[Control]:
	var cells: Array[Control] = []
	cells.resize(CardInventory.SLOT_COUNT)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", gap * 2)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(row)
	var ace: Control = make_cell.call(CardInventory.ACE_SLOT)
	ace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(ace)
	cells[CardInventory.ACE_SLOT] = ace
	var grid: GridContainer = GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", gap)
	grid.add_theme_constant_override("v_separation", gap)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(grid)
	for slot: int in range(1, CardInventory.RANK_SLOTS):
		var cell: Control = make_cell.call(slot)
		grid.add_child(cell)
		cells[slot] = cell
	var pack: VBoxContainer = VBoxContainer.new()
	pack.add_theme_constant_override("separation", gap)
	pack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(pack)
	for slot: int in range(CardInventory.RANK_SLOTS, CardInventory.SLOT_COUNT):
		var cell: Control = make_cell.call(slot)
		cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
		pack.add_child(cell)
		cells[slot] = cell
	return cells
