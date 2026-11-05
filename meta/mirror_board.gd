class_name MirrorBoard
extends Resource
## The Mirror's rows, in display order.

@export var rows: Array[MirrorRow] = []


func find_row(id: StringName) -> MirrorRow:
	for row: MirrorRow in rows:
		if row.id == id:
			return row
	return null
