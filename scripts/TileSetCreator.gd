class_name TileSetCreator
extends RefCounted

## Creates a programmatic TileSet for castle rooms
## Generates 16x16 colored tiles with borders for visual depth

const TILE_SIZE = 16

# Tile type definitions
enum TileType {
	FLOOR,          # Brown floor
	WALL,           # Dark gray wall
	WALL_TOP,       # Light gray wall top (3D effect)
	CARPET_RED,     # Red carpet decoration
	STONE,          # Gray stone
	DOOR,           # Dark brown door marker
	FLOOR_STONE,    # Stone floor pattern
	HIGHLIGHT       # Golden highlight for special items
}

# Color palette for castle tiles
const TILE_COLORS = {
	TileType.FLOOR: Color(0.4, 0.3, 0.2),        # Brown
	TileType.WALL: Color(0.3, 0.3, 0.3),         # Dark gray
	TileType.WALL_TOP: Color(0.5, 0.5, 0.5),     # Light gray
	TileType.CARPET_RED: Color(0.7, 0.2, 0.2),   # Red
	TileType.STONE: Color(0.5, 0.5, 0.5),        # Medium gray
	TileType.DOOR: Color(0.5, 0.3, 0.1),         # Dark brown
	TileType.FLOOR_STONE: Color(0.35, 0.35, 0.35), # Dark stone
	TileType.HIGHLIGHT: Color(0.8, 0.7, 0.3)     # Gold
}

static func create_castle_tileset() -> TileSet:
	"""Create a complete TileSet for castle rooms"""
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Create atlas source
	var atlas_source = TileSetAtlasSource.new()

	# Create atlas image (4 tiles wide x 2 tiles tall = 8 tiles)
	var atlas_width = 4
	var atlas_height = 2
	var atlas_image = Image.create(
		TILE_SIZE * atlas_width,
		TILE_SIZE * atlas_height,
		false,
		Image.FORMAT_RGBA8
	)

	# Paint all tiles
	for tile_type in TileType.values():
		var color = TILE_COLORS[tile_type]
		var atlas_x = (tile_type % atlas_width) * TILE_SIZE
		var atlas_y = (tile_type / atlas_width) * TILE_SIZE

		paint_tile(atlas_image, atlas_x, atlas_y, color)

	# Create texture from image
	var atlas_texture = ImageTexture.create_from_image(atlas_image)
	atlas_source.texture = atlas_texture
	tileset.add_source(atlas_source, 0)

	# Create individual tiles in atlas
	for tile_type in TileType.values():
		var atlas_coords = Vector2i(tile_type % atlas_width, tile_type / atlas_width)
		atlas_source.create_tile(atlas_coords)

		# Store metadata
		var tile_data = atlas_source.get_tile_data(atlas_coords, 0)
		tile_data.set_custom_data("tile_type", TileType.keys()[tile_type])

	# Add physics layer for collisions
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)  # World layer
	tileset.set_physics_layer_collision_mask(0, 0)   # No mask (static)

	# Add collision to wall tiles
	add_wall_collision(atlas_source, TileType.WALL)
	add_wall_collision(atlas_source, TileType.WALL_TOP)

	return tileset

static func paint_tile(image: Image, start_x: int, start_y: int, base_color: Color):
	"""Paint a 16x16 tile with border shading for depth"""
	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			var color = base_color

			# Add border effect for depth
			var is_border = (x == 0 or y == 0 or x == TILE_SIZE - 1 or y == TILE_SIZE - 1)
			var is_inner_border = (x == 1 or y == 1 or x == TILE_SIZE - 2 or y == TILE_SIZE - 2)

			if is_border:
				# Darker outer border
				color = base_color.darkened(0.3)
			elif is_inner_border:
				# Lighter inner border (top-left highlight)
				if x == 1 and y < TILE_SIZE - 2:
					color = base_color.lightened(0.15)
				elif y == 1 and x < TILE_SIZE - 2:
					color = base_color.lightened(0.15)
				# Darker inner border (bottom-right shadow)
				elif x == TILE_SIZE - 2 and y > 1:
					color = base_color.darkened(0.15)
				elif y == TILE_SIZE - 2 and x > 1:
					color = base_color.darkened(0.15)

			image.set_pixel(start_x + x, start_y + y, color)

static func add_wall_collision(atlas_source: TileSetAtlasSource, tile_type: TileType):
	"""Add collision polygon to a wall tile"""
	var tile_coords = Vector2i(tile_type % 4, tile_type / 4)
	var tile_data = atlas_source.get_tile_data(tile_coords, 0)

	if not tile_data:
		return

	# Create full-tile collision rectangle
	var collision_polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(TILE_SIZE, 0),
		Vector2(TILE_SIZE, TILE_SIZE),
		Vector2(0, TILE_SIZE)
	])

	tile_data.set_collision_polygons_count(0, 1)
	tile_data.set_collision_polygon_points(0, 0, collision_polygon)

static func get_tile_coords(tile_type: TileType) -> Vector2i:
	"""Get atlas coordinates for a tile type"""
	return Vector2i(tile_type % 4, tile_type / 4)
