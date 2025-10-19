extends Control

# Main battle scene controller

@onready var party_container = $PartyContainer
@onready var enemy_container = $EnemyContainer
@onready var action_panel = $ActionPanel
@onready var message_label = $MessageLabel

var party_sprites: Array = []
var enemy_sprites: Array = []
var current_combatant_index: int = 0

# Battle state
var player_action_selected: bool = false
var awaiting_player_input: bool = false

func _ready():
	# Connect to BattleManager signals
	BattleManager.battle_started.connect(_on_battle_started)
	BattleManager.turn_changed.connect(_on_turn_changed)
	BattleManager.battle_ended.connect(_on_battle_ended)
	BattleManager.damage_dealt.connect(_on_damage_dealt)
	BattleManager.action_performed.connect(_on_action_performed)

	# Hide action panel initially
	action_panel.visible = false

	# Start the battle
	_on_battle_started()

func _on_battle_started():
	display_message("Battle started!")
	setup_combatants()
	await get_tree().create_timer(1.0).timeout
	start_turn_sequence()

func setup_combatants():
	"""Create visual representations of party and enemies"""
	# Clear existing sprites
	for child in party_container.get_children():
		child.queue_free()
	for child in enemy_container.get_children():
		child.queue_free()

	party_sprites.clear()
	enemy_sprites.clear()

	# Create party member sprites
	var party_colors = [
		Color(0.290, 0.564, 0.886),  # Blue - Hero
		Color(0.804, 0.361, 0.361),  # Red - Warrior
		Color(0.608, 0.349, 0.714)   # Purple - Mage
	]

	for i in range(GameManager.party.size()):
		var character = GameManager.party[i]
		var sprite = create_combatant_sprite(character, party_colors[i], false)
		party_container.add_child(sprite)
		party_sprites.append(sprite)

	# Create enemy sprites
	var enemy_colors = {
		"Goblin": Color(0.906, 0.298, 0.235),
		"Skeleton": Color(0.902, 0.494, 0.133),
		"Knight": Color(0.608, 0.349, 0.714)
	}

	for enemy in BattleManager.current_enemies:
		var color = enemy_colors.get(enemy["name"], Color.RED)
		var sprite = create_combatant_sprite(enemy, color, true)
		enemy_container.add_child(sprite)
		enemy_sprites.append(sprite)

func create_combatant_sprite(combatant: Dictionary, color: Color, is_enemy: bool) -> Control:
	"""Create a visual representation of a combatant"""
	var container = VBoxContainer.new()

	# Name label
	var name_label = Label.new()
	name_label.text = combatant["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(name_label)

	# Sprite (colored rectangle)
	var sprite_rect = ColorRect.new()
	sprite_rect.custom_minimum_size = Vector2(32, 32)
	sprite_rect.color = color
	container.add_child(sprite_rect)

	# HP bar
	var hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(64, 8)
	hp_bar.max_value = combatant["max_hp"]
	hp_bar.value = combatant["current_hp"]
	hp_bar.show_percentage = false
	container.add_child(hp_bar)

	# HP label
	var hp_label = Label.new()
	hp_label.text = "%d/%d" % [combatant["current_hp"], combatant["max_hp"]]
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(hp_label)

	# Store reference to combatant data
	container.set_meta("combatant", combatant)
	container.set_meta("hp_bar", hp_bar)
	container.set_meta("hp_label", hp_label)

	return container

func start_turn_sequence():
	"""Begin processing turns"""
	process_next_turn()

func process_next_turn():
	"""Process the current turn"""
	if BattleManager.turn_queue.is_empty():
		return

	var current = BattleManager.get_current_combatant()

	if current.is_empty():
		return

	# Highlight current combatant
	highlight_current_combatant()

	if current.has("is_enemy"):
		# Enemy turn - AI controlled
		display_message("%s's turn..." % current["name"])
		await get_tree().create_timer(1.0).timeout
		BattleManager.enemy_ai_action(current)
		await get_tree().create_timer(1.0).timeout
		BattleManager.next_turn()
	else:
		# Player party member turn
		display_message("%s's turn!" % current["name"])
		show_action_menu()

func show_action_menu():
	"""Display action buttons for player"""
	action_panel.visible = true
	awaiting_player_input = true

func hide_action_menu():
	action_panel.visible = false
	awaiting_player_input = false

func _on_attack_button_pressed():
	if not awaiting_player_input:
		return

	hide_action_menu()
	var attacker = BattleManager.get_current_combatant()

	# Select random alive enemy
	var alive_enemies = []
	for enemy in BattleManager.current_enemies:
		if enemy["current_hp"] > 0:
			alive_enemies.append(enemy)

	if alive_enemies.is_empty():
		return

	var target = alive_enemies[randi() % alive_enemies.size()]
	BattleManager.perform_attack(attacker, target)

	await get_tree().create_timer(1.5).timeout
	BattleManager.next_turn()

func _on_defend_button_pressed():
	if not awaiting_player_input:
		return

	hide_action_menu()
	var defender = BattleManager.get_current_combatant()
	BattleManager.perform_defend(defender)

	await get_tree().create_timer(1.0).timeout
	BattleManager.next_turn()

func _on_items_button_pressed():
	if not awaiting_player_input:
		return

	# Simple implementation: use healing potion on self
	var current = BattleManager.get_current_combatant()

	# Find party member index
	var party_index = -1
	for i in range(GameManager.party.size()):
		if GameManager.party[i]["name"] == current["name"]:
			party_index = i
			break

	if party_index >= 0:
		if BattleManager.use_item_on_target("healing_potion", party_index):
			display_message("%s used a healing potion!" % current["name"])
			update_all_hp_displays()
			await get_tree().create_timer(1.5).timeout
			hide_action_menu()
			BattleManager.next_turn()
		else:
			display_message("No items available!")

func _on_run_button_pressed():
	if not awaiting_player_input:
		return

	hide_action_menu()
	display_message("Attempting to flee...")

	await get_tree().create_timer(1.0).timeout

	if BattleManager.perform_run():
		display_message("Fled successfully!")
		await get_tree().create_timer(1.0).timeout
		return_to_overworld()
	else:
		display_message("Couldn't escape!")
		await get_tree().create_timer(1.0).timeout
		BattleManager.next_turn()

func _on_turn_changed(combatant):
	"""Called when turn changes"""
	process_next_turn()

func _on_damage_dealt(target, amount):
	"""Called when damage is dealt"""
	display_message("%d damage!" % amount)
	update_all_hp_displays()

func _on_action_performed(combatant, action_name):
	"""Called when an action is performed"""
	display_message("%s used %s!" % [combatant["name"], action_name])

func _on_battle_ended(victory: bool):
	"""Called when battle ends"""
	if victory:
		display_message("Victory!")
		await get_tree().create_timer(2.0).timeout

		# Show rewards
		var xp_gained = 0
		for enemy in BattleManager.current_enemies:
			xp_gained += enemy["xp_reward"]

		display_message("Gained %d XP!" % xp_gained)
		await get_tree().create_timer(2.0).timeout
		return_to_overworld()
	else:
		display_message("Defeated...")
		await get_tree().create_timer(2.0).timeout
		game_over()

func return_to_overworld():
	"""Return to the overworld after battle"""
	# Mark enemies as defeated in the room
	for enemy in BattleManager.current_enemies:
		# Enemies are already tracked by the overworld Enemy nodes
		pass

	# Go back to starting room
	get_tree().change_scene_to_file("res://scenes/overworld/Room.tscn")

func game_over():
	"""Transition to game over screen"""
	get_tree().change_scene_to_file("res://scenes/ui/GameOver.tscn")

func display_message(text: String):
	"""Display a message to the player"""
	if message_label:
		message_label.text = text

func update_all_hp_displays():
	"""Update HP bars and labels for all combatants"""
	# Update party
	for i in range(party_sprites.size()):
		if i < GameManager.party.size():
			var sprite = party_sprites[i]
			var character = GameManager.party[i]
			var hp_bar = sprite.get_meta("hp_bar")
			var hp_label = sprite.get_meta("hp_label")

			hp_bar.value = character["current_hp"]
			hp_label.text = "%d/%d" % [character["current_hp"], character["max_hp"]]

	# Update enemies
	for i in range(enemy_sprites.size()):
		if i < BattleManager.current_enemies.size():
			var sprite = enemy_sprites[i]
			var enemy = BattleManager.current_enemies[i]
			var hp_bar = sprite.get_meta("hp_bar")
			var hp_label = sprite.get_meta("hp_label")

			hp_bar.value = enemy["current_hp"]
			hp_label.text = "%d/%d" % [enemy["current_hp"], enemy["max_hp"]]

func highlight_current_combatant():
	"""Visual highlight for whose turn it is"""
	# This could add a visual indicator in the future
	pass
