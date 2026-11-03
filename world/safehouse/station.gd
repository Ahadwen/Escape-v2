class_name Station
extends Node3D
## A thing in a hub scene you walk up to and interact with (shop counter,
## trader, exit door). Greybox: a coloured block with a floating name.

signal used(player: Player)

@export var title: String = "Station"
@export var prompt: String = "Use"
@export var color: Color = Color(0.6, 0.6, 0.7)
@export var size: Vector3 = Vector3(2.0, 1.2, 1.2)

@onready var interactable: Interactable = $Interactable


func _ready() -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	box.material = material
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.mesh = box
	mesh.position = Vector3(0.0, size.y * 0.5, 0.0)
	add_child(mesh)
	var body: StaticBody3D = StaticBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	shape.position = mesh.position
	body.add_child(shape)
	add_child(body)
	var label: Label3D = Label3D.new()
	label.text = title
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 64
	label.outline_size = 12
	label.position = Vector3(0.0, size.y + 0.9, 0.0)
	add_child(label)
	interactable.prompt = prompt
	interactable.interact_range = maxf(size.x, size.z) * 0.5 + 1.4
	interactable.interacted.connect(func(player: Player) -> void: used.emit(player))
