extends Node2D

# Room manager script
# Handles room layout, enemies, and transitions

@export var room_id: String = "room_0_0"
@export var room_width: int = 10
@export var room_height: int = 10

const TILE_SIZE = 16

func _ready():
	GameManager.current_room = room_id
	setup_room()

func setup_room():
	# Room setup is done in the scene editor or can be generated here
	pass

func add_wall_border():
	"""Helper to add walls around the room perimeter"""
	# This would be called if generating rooms procedurally
	# For now, rooms are designed in the editor
	pass
