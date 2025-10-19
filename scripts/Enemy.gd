extends CharacterBody2D

# Enemy controller for overworld

@export var enemy_type: String = "goblin"  # goblin, skeleton, knight
@export var enemy_id: String = "enemy_0"  # Unique ID for tracking defeats
@export var patrol_range: float = 32.0
@export var patrol_speed: float = 30.0

var start_position: Vector2
var patrol_direction: Vector2 = Vector2.RIGHT
var patrol_timer: float = 0.0
var change_direction_time: float = 2.0

var color_map = {
	"goblin": Color(0.906, 0.298, 0.235),  # Red
	"skeleton": Color(0.902, 0.494, 0.133),  # Orange
	"knight": Color(0.608, 0.349, 0.714)  # Purple
}

func _ready():
	start_position = position
	randomize_patrol_direction()

	# Set color based on enemy type
	if has_node("Sprite"):
		$Sprite.color = color_map.get(enemy_type, Color.RED)

	# Check if already defeated
	if GameManager.is_enemy_defeated(GameManager.current_room, enemy_id):
		queue_free()

func _physics_process(delta):
	if BattleManager.in_battle:
		velocity = Vector2.ZERO
		return

	# Simple patrol AI
	patrol_timer += delta

	if patrol_timer >= change_direction_time:
		randomize_patrol_direction()
		patrol_timer = 0.0

	# Move in patrol direction
	velocity = patrol_direction * patrol_speed

	# Keep within patrol range
	var distance_from_start = position.distance_to(start_position)
	if distance_from_start > patrol_range:
		# Turn back toward start
		patrol_direction = (start_position - position).normalized()

	move_and_slide()

func randomize_patrol_direction():
	# Choose random cardinal direction (removed ZERO to prevent freezing)
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	patrol_direction = directions[randi() % directions.size()]

func _on_player_collision(body):
	if body.name == "Player" and not BattleManager.in_battle:
		start_battle()

func start_battle():
	# Trigger battle with this enemy type, passing our ID for tracking
	BattleManager.start_battle([enemy_type], enemy_id, GameManager.current_room)

	# Small delay to ensure BattleManager completes initialization
	await get_tree().process_frame

	# Transition to battle scene
	get_tree().change_scene_to_file("res://scenes/battle/BattleScene.tscn")
