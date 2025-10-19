extends Node2D

# Room manager script
# Handles room layout, enemies, and transitions

@export var room_id: String = "room_0_0"
@export var room_width: int = 10
@export var room_height: int = 10
@export var room_theme: String = "normal"  # normal, dungeon, treasure

const TILE_SIZE = 16

var visual_room: VisualRoom

func _ready():
	GameManager.current_room = room_id
	setup_visual_room()
	setup_room()

func setup_visual_room():
	"""Create and configure the visual TileMap-based room"""
	# Create VisualRoom instance
	visual_room = VisualRoom.new()
	visual_room.room_width = room_width
	visual_room.room_height = room_height
	visual_room.room_theme = room_theme
	visual_room.name = "VisualRoom"

	# Add as first child to ensure it renders behind entities
	add_child(visual_room)
	move_child(visual_room, 0)

	# Wait for room to be painted
	await visual_room.room_painted

	# Create doorways at Door positions
	create_doorways_from_doors()

func create_doorways_from_doors():
	"""Find all Door nodes and create doorway openings in walls"""
	for child in get_children():
		if child is Node2D and child.has_method("try_open_door"):
			# This is a Door node
			var door_grid_pos = visual_room.world_to_grid(child.position)

			# Determine direction based on position
			var direction = Vector2i.ZERO
			if door_grid_pos.y == 0 or door_grid_pos.y == 1:
				direction = Vector2i.UP
			elif door_grid_pos.y >= room_height - 2:
				direction = Vector2i.DOWN
			elif door_grid_pos.x == 0:
				direction = Vector2i.LEFT
			elif door_grid_pos.x >= room_width - 1:
				direction = Vector2i.RIGHT

			visual_room.create_doorway(door_grid_pos, direction)

	# Add highlights for special items (sword upgrades)
	add_item_highlights()

func add_item_highlights():
	"""Add golden highlights under special items like sword upgrades"""
	# Search through all entities for SwordUpgrade nodes
	var entities_node = get_node_or_null("Entities")
	if not entities_node:
		return

	for child in entities_node.get_children():
		# Check if this is a SwordUpgrade (has upgrade_id property)
		if child.has_method("get") and child.get("upgrade_id"):
			# Add golden highlight at this position
			var item_grid_pos = visual_room.world_to_grid(child.position)
			visual_room.add_highlight(item_grid_pos)

func setup_room():
	# Room setup is done in the scene editor or can be generated here
	pass

func add_wall_border():
	"""Helper to add walls around the room perimeter"""
	# This would be called if generating rooms procedurally
	# For now, rooms are designed in the editor
	pass
