extends CharacterBody2D

# Player controller for overworld movement

const SPEED = 80.0
const TILE_SIZE = 16

# Movement state
var is_moving = false
var movement_direction = Vector2.ZERO

func _ready():
	# Set z_index to render above room layers (floor=0, walls=1, decorations=2)
	z_index = 3

	# Use saved position from GameManager if available
	if GameManager.player_position != Vector2.ZERO:
		position = GameManager.player_position
		GameManager.player_position = Vector2.ZERO  # Reset after using

	# Ensure player snaps to grid
	position = position.snapped(Vector2(TILE_SIZE, TILE_SIZE))

func _physics_process(_delta):
	if BattleManager.in_battle:
		return  # Don't move during battle

	# Get input direction
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Normalize diagonal movement
	if input_direction != Vector2.ZERO:
		input_direction = input_direction.normalized()

	velocity = input_direction * SPEED
	move_and_slide()

func _input(event):
	# Handle discrete movement for grid-snapping (optional alternative)
	pass
