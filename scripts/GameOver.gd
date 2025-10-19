extends Control

# Game Over screen

func _ready():
	pass

func _on_restart_button_pressed():
	# Reset game state completely
	GameManager.initialize_party()
	GameManager.keys = 0
	GameManager.sword_level = 1
	GameManager.update_sword_bonus()
	GameManager.defeated_enemies.clear()
	GameManager.unlocked_doors.clear()
	GameManager.collected_upgrades.clear()

	# Reset position and room
	GameManager.current_room = "room_0_0"
	GameManager.player_position = Vector2.ZERO

	# Reset inventory
	GameManager.inventory = {
		"healing_potion": 3  # Start with 3 potions
	}

	# Return to starting room
	get_tree().change_scene_to_file("res://scenes/overworld/Room.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
