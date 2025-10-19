extends Control

# Game Over screen

func _ready():
	pass

func _on_restart_button_pressed():
	# Reset game state
	GameManager.initialize_party()
	GameManager.keys = 0
	GameManager.sword_level = 1
	GameManager.update_sword_bonus()
	GameManager.defeated_enemies.clear()
	GameManager.unlocked_doors.clear()

	# Return to starting room
	get_tree().change_scene_to_file("res://scenes/overworld/Room.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
