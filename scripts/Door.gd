extends Area2D

# Door for transitioning between rooms

@export var door_id: String = "door_0"
@export var is_locked: bool = false
@export var target_room: String = ""  # Path to target room scene
@export var target_position: Vector2 = Vector2.ZERO

var player_nearby: bool = false

func _ready():
	# Check if door has been unlocked
	if GameManager.is_door_unlocked(door_id):
		is_locked = false

	update_appearance()

func _process(_delta):
	if player_nearby and Input.is_action_just_pressed("ui_accept"):
		try_open_door()

func try_open_door():
	if is_locked:
		# Try to use a key
		if GameManager.use_key():
			is_locked = false
			GameManager.unlock_door(door_id)
			update_appearance()
			print("Door unlocked!")
			# Small delay then transition
			await get_tree().create_timer(0.5).timeout
			transition_to_room()
		else:
			print("This door is locked. You need a key!")
	else:
		transition_to_room()

func transition_to_room():
	if target_room == "":
		print("No target room set!")
		return

	# Save player position for respawn
	GameManager.player_position = target_position

	# Change scene
	get_tree().change_scene_to_file(target_room)

func update_appearance():
	# Update door color based on locked status
	if has_node("Sprite"):
		if is_locked:
			$Sprite.color = Color(0.545, 0.271, 0.075)  # Brown (locked)
		else:
			$Sprite.color = Color(0.824, 0.412, 0.118)  # Light brown (unlocked)

func _on_body_entered(body):
	if body.name == "Player":
		player_nearby = true

func _on_body_exited(body):
	if body.name == "Player":
		player_nearby = false
