extends Node

# Battle state manager
# Handles turn order, combat actions, and battle flow

signal battle_started
signal turn_changed(combatant)
signal battle_ended(victory: bool)
signal damage_dealt(target, amount)
signal action_performed(combatant, action_name)

# Battle state
var in_battle: bool = false
var current_enemies: Array[Dictionary] = []
var turn_queue: Array[Dictionary] = []
var current_turn_index: int = 0
var battle_scene_path: String = "res://scenes/battle/BattleScene.tscn"

# Track which overworld enemy triggered the battle
var triggering_enemy_id: String = ""
var triggering_room_id: String = ""

# Enemy data templates
var enemy_templates: Dictionary = {
	"goblin": {
		"name": "Goblin",
		"max_hp": 20,
		"base_str": 5,
		"base_def": 3,
		"base_lck": 5,
		"xp_reward": 25,
		"key_drop_chance": 0.3
	},
	"skeleton": {
		"name": "Skeleton",
		"max_hp": 25,
		"base_str": 7,
		"base_def": 4,
		"base_lck": 3,
		"xp_reward": 35,
		"key_drop_chance": 0.4
	},
	"knight": {
		"name": "Knight",
		"max_hp": 40,
		"base_str": 10,
		"base_def": 8,
		"base_lck": 4,
		"xp_reward": 60,
		"key_drop_chance": 0.6
	}
}

func start_battle(enemies: Array[String], enemy_id: String = "", room_id: String = ""):
	"""Initialize a new battle with given enemy types"""
	in_battle = true
	current_enemies.clear()

	# Store info about the overworld enemy that triggered this battle
	triggering_enemy_id = enemy_id
	triggering_room_id = room_id

	# Create enemy instances
	for enemy_type in enemies:
		if enemy_templates.has(enemy_type):
			var template = enemy_templates[enemy_type]
			var enemy = {
				"name": template["name"],
				"max_hp": template["max_hp"],
				"current_hp": template["max_hp"],
				"base_str": template["base_str"],
				"base_def": template["base_def"],
				"base_lck": template["base_lck"],
				"xp_reward": template["xp_reward"],
				"key_drop_chance": template["key_drop_chance"],
				"defending": false,
				"is_enemy": true
			}
			current_enemies.append(enemy)

	# Build turn queue
	build_turn_queue()
	current_turn_index = 0

	battle_started.emit()

func build_turn_queue():
	"""Build the turn order based on LCK stat (speed)"""
	turn_queue.clear()

	# Add all party members (use direct references, not duplicates)
	for character in GameManager.party:
		if character["current_hp"] > 0:
			turn_queue.append(character)

	# Add all enemies
	for enemy in current_enemies:
		if enemy["current_hp"] > 0:
			turn_queue.append(enemy)

	# Sort by LCK (higher goes first)
	turn_queue.sort_custom(func(a, b): return a["base_lck"] > b["base_lck"])

func get_current_combatant() -> Dictionary:
	"""Get the current combatant whose turn it is"""
	if turn_queue.is_empty():
		return {}
	return turn_queue[current_turn_index]

func next_turn():
	"""Move to the next turn"""
	current_turn_index += 1

	# If we've gone through everyone, rebuild queue (new round)
	if current_turn_index >= turn_queue.size():
		build_turn_queue()
		current_turn_index = 0
		# Defending status is now cleared when damage is taken

	# Skip dead combatants
	while current_turn_index < turn_queue.size():
		var combatant = turn_queue[current_turn_index]
		if combatant["current_hp"] > 0:
			break
		current_turn_index += 1

	if current_turn_index < turn_queue.size():
		turn_changed.emit(get_current_combatant())

func perform_attack(attacker: Dictionary, target: Dictionary):
	"""Execute an attack action"""
	var damage = calculate_damage(attacker, target)
	target["current_hp"] = max(0, target["current_hp"] - damage)

	# Clear defending status after taking damage
	target["defending"] = false

	damage_dealt.emit(target, damage)
	action_performed.emit(attacker, "Attack")

	# Emit signal to update HUD if party member HP changed
	if not target.has("is_enemy"):
		GameManager.party_stats_changed.emit()

	# No need to sync - we're using direct references now
	check_battle_end()

func perform_defend(character: Dictionary):
	"""Set character to defending state"""
	character["defending"] = true
	action_performed.emit(character, "Defend")

func perform_run() -> bool:
	"""Attempt to flee from battle"""
	# Simple 50% success rate
	var success = randf() > 0.5
	if success:
		end_battle(false, true)  # Fled, not defeated
	return success

func use_item_on_target(item_name: String, target_index: int) -> bool:
	"""Use an item from inventory on a target"""
	if not GameManager.use_item(item_name):
		return false

	# For now, only healing potions
	if item_name == "healing_potion":
		GameManager.heal_party_member(target_index, 20)
		# Using direct references - HP is already updated

	return true

func calculate_damage(attacker: Dictionary, defender: Dictionary) -> int:
	"""Calculate damage dealt from attacker to defender"""
	var base_damage: int

	# Get STR (includes sword bonus if applicable)
	if attacker.has("is_enemy"):
		base_damage = attacker["base_str"]
	else:
		base_damage = GameManager.get_stat(attacker, "str")

	var defense = defender["base_def"]

	# If defending, double defense
	if defender.get("defending", false):
		defense *= 2

	# Damage = ATK - DEF, minimum 1
	var damage = max(1, base_damage - defense)

	# Add some randomness (+/- 20%)
	var variance = randf_range(0.8, 1.2)
	damage = int(damage * variance)

	return max(1, damage)

func enemy_ai_action(enemy: Dictionary):
	"""Perform an AI action for an enemy"""
	# Random choice between attack and defend (70% attack, 30% defend)
	if randf() < 0.7:
		# Attack random alive party member
		var alive_party = []
		for i in range(GameManager.party.size()):
			if GameManager.party[i]["current_hp"] > 0:
				alive_party.append(i)

		if alive_party.is_empty():
			return

		var target_index = alive_party[randi() % alive_party.size()]
		var target = GameManager.party[target_index]
		perform_attack(enemy, target)
	else:
		# Defend
		perform_defend(enemy)

func check_battle_end():
	"""Check if battle has ended (all enemies or all party dead)"""
	var all_enemies_dead = true
	for enemy in current_enemies:
		if enemy["current_hp"] > 0:
			all_enemies_dead = false
			break

	if all_enemies_dead:
		end_battle(true)
		return

	if not GameManager.is_party_alive():
		end_battle(false)
		return

func end_battle(victory: bool, fled: bool = false):
	"""End the battle and distribute rewards if victorious"""
	in_battle = false

	if victory and not fled:
		# Grant XP only from defeated enemies
		var total_xp = 0
		for enemy in current_enemies:
			if enemy["current_hp"] <= 0:
				total_xp += enemy["xp_reward"]

		if total_xp > 0:
			GameManager.add_xp_to_party(total_xp)

		# Check for key drops only from defeated enemies
		for enemy in current_enemies:
			if enemy["current_hp"] <= 0:
				if randf() < enemy["key_drop_chance"]:
					GameManager.add_key()

		# Mark the overworld enemy as defeated
		if triggering_enemy_id != "" and triggering_room_id != "":
			GameManager.mark_enemy_defeated(triggering_room_id, triggering_enemy_id)

	battle_ended.emit(victory)

func is_enemy_turn() -> bool:
	"""Check if current turn belongs to an enemy"""
	if turn_queue.is_empty():
		return false
	return get_current_combatant().has("is_enemy")
