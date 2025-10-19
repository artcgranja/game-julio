class_name VisualRoom
extends Node2D

## Visual room manager using TileMapLayer
## Paints floors, walls, and decorations for castle rooms

signal room_painted

@export var room_width: int = 10
@export var room_height: int = 10
@export var room_theme: String = "normal"  # normal, dungeon, treasure

const TILE_SIZE = 16

# Layer references
var floor_layer: TileMapLayer
var wall_layer: TileMapLayer
var decoration_layer: TileMapLayer

# Tileset
var tileset: TileSet

# Theme color overrides
var theme_colors = {
	"normal": {
		"floor": Color(0.4, 0.3, 0.2),
		"wall": Color(0.3, 0.3, 0.3),
		"wall_top": Color(0.5, 0.5, 0.5)
	},
	"dungeon": {
		"floor": Color(0.35, 0.35, 0.35),
		"wall": Color(0.23, 0.23, 0.23),
		"wall_top": Color(0.33, 0.33, 0.33)
	},
	"treasure": {
		"floor": Color(0.48, 0.47, 0.42),
		"wall": Color(0.42, 0.40, 0.31),
		"wall_top": Color(0.54, 0.52, 0.44)
	}
}

func _ready():
	setup_tilemap_layers()
	paint_room()

func setup_tilemap_layers():
	"""Create and configure TileMapLayer nodes"""
	# Create tileset
	tileset = TileSetCreator.create_castle_tileset()

	# Apply theme-specific colors if needed
	if room_theme != "normal":
		apply_theme_colors()

	# Create floor layer
	floor_layer = TileMapLayer.new()
	floor_layer.name = "FloorLayer"
	floor_layer.tile_set = tileset
	floor_layer.z_index = 0
	floor_layer.y_sort_enabled = false
	add_child(floor_layer)
	move_child(floor_layer, 0)

	# Create wall layer with collision
	wall_layer = TileMapLayer.new()
	wall_layer.name = "WallLayer"
	wall_layer.tile_set = tileset
	wall_layer.z_index = 1
	wall_layer.y_sort_enabled = false
	wall_layer.collision_enabled = true
	add_child(wall_layer)
	move_child(wall_layer, 1)

	# Create decoration layer
	decoration_layer = TileMapLayer.new()
	decoration_layer.name = "DecorationLayer"
	decoration_layer.tile_set = tileset
	decoration_layer.z_index = 2
	decoration_layer.y_sort_enabled = false
	add_child(decoration_layer)
	move_child(decoration_layer, 2)

func apply_theme_colors():
	"""Apply theme-specific color modifications to tileset"""
	# This would require recreating the tileset with theme colors
	# For now, we'll use the predefined tile types and just vary decorations
	pass

func paint_room():
	"""Paint the complete room layout"""
	paint_floor()
	paint_walls()
	paint_theme_decorations()
	room_painted.emit()

func paint_floor():
	"""Paint the floor tiles"""
	var floor_tile = TileSetCreator.get_tile_coords(TileSetCreator.TileType.FLOOR)

	# Use stone floor for dungeon theme
	if room_theme == "dungeon":
		floor_tile = TileSetCreator.get_tile_coords(TileSetCreator.TileType.FLOOR_STONE)

	for x in range(room_width):
		for y in range(room_height):
			floor_layer.set_cell(Vector2i(x, y), 0, floor_tile)

func paint_walls():
	"""Paint wall tiles with 3D effect"""
	var wall_tile = TileSetCreator.get_tile_coords(TileSetCreator.TileType.WALL)
	var wall_top_tile = TileSetCreator.get_tile_coords(TileSetCreator.TileType.WALL_TOP)

	# Top wall (with lighter top for 3D effect)
	for x in range(room_width):
		wall_layer.set_cell(Vector2i(x, 0), 0, wall_top_tile)
		wall_layer.set_cell(Vector2i(x, 1), 0, wall_tile)

	# Bottom wall
	for x in range(room_width):
		wall_layer.set_cell(Vector2i(x, room_height - 1), 0, wall_tile)

	# Left and right walls
	for y in range(room_height):
		wall_layer.set_cell(Vector2i(0, y), 0, wall_tile)
		wall_layer.set_cell(Vector2i(room_width - 1, y), 0, wall_tile)

func paint_theme_decorations():
	"""Paint decorations based on room theme"""
	match room_theme:
		"normal":
			paint_normal_decorations()
		"dungeon":
			paint_dungeon_decorations()
		"treasure":
			paint_treasure_decorations()

func paint_normal_decorations():
	"""Paint decorations for normal room - small carpet"""
	var carpet_tile = TileSetCreator.get_tile_coords(TileSetCreator.TileType.CARPET_RED)

	# Small 2x2 carpet in center
	var center_x = room_width / 2
	var center_y = room_height / 2

	for x in range(center_x - 1, center_x + 1):
		for y in range(center_y - 1, center_y + 1):
			if x > 0 and x < room_width - 1 and y > 0 and y < room_height - 1:
				decoration_layer.set_cell(Vector2i(x, y), 0, carpet_tile)

func paint_dungeon_decorations():
	"""Paint decorations for dungeon room - stone pattern"""
	var stone_tile = TileSetCreator.get_tile_coords(TileSetCreator.TileType.STONE)

	# Checkerboard stone pattern on floor
	for x in range(2, room_width - 2):
		for y in range(2, room_height - 2):
			if (x + y) % 2 == 0:
				floor_layer.set_cell(Vector2i(x, y), 0, stone_tile)

func paint_treasure_decorations():
	"""Paint decorations for treasure room - large carpet"""
	var carpet_tile = TileSetCreator.get_tile_coords(TileSetCreator.TileType.CARPET_RED)

	# Large 4x4 carpet
	var center_x = room_width / 2
	var center_y = room_height / 2

	for x in range(center_x - 2, center_x + 2):
		for y in range(center_y - 2, center_y + 2):
			if x > 0 and x < room_width - 1 and y > 0 and y < room_height - 1:
				decoration_layer.set_cell(Vector2i(x, y), 0, carpet_tile)

func add_highlight(grid_pos: Vector2i):
	"""Add a golden highlight at a specific position (for item locations)"""
	var highlight_tile = TileSetCreator.get_tile_coords(TileSetCreator.TileType.HIGHLIGHT)
	decoration_layer.set_cell(grid_pos, 0, highlight_tile)

func create_doorway(grid_pos: Vector2i, direction: Vector2i = Vector2i.ZERO):
	"""Create a doorway opening in the wall"""
	# Clear wall tiles
	wall_layer.erase_cell(grid_pos)

	# If horizontal door, clear neighbor too
	if direction == Vector2i.LEFT or direction == Vector2i.RIGHT:
		wall_layer.erase_cell(grid_pos + Vector2i(0, 1))
	# If vertical door, clear neighbor too
	elif direction == Vector2i.UP or direction == Vector2i.DOWN:
		wall_layer.erase_cell(grid_pos + Vector2i(1, 0))

func world_to_grid(world_pos: Vector2) -> Vector2i:
	"""Convert world position to grid coordinates"""
	return Vector2i(
		int(world_pos.x / TILE_SIZE),
		int(world_pos.y / TILE_SIZE)
	)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	"""Convert grid coordinates to world position (center of tile)"""
	return Vector2(
		grid_pos.x * TILE_SIZE + TILE_SIZE / 2.0,
		grid_pos.y * TILE_SIZE + TILE_SIZE / 2.0
	)

func get_room_center() -> Vector2:
	"""Get the world position of the room center"""
	return grid_to_world(Vector2i(room_width / 2, room_height / 2))

func is_valid_grid_pos(grid_pos: Vector2i) -> bool:
	"""Check if grid position is within room bounds"""
	return (grid_pos.x >= 0 and grid_pos.x < room_width and
			grid_pos.y >= 0 and grid_pos.y < room_height)
