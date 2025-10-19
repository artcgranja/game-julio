extends Node

# Global game state manager
# Handles party, inventory, progression, and game state

# Signals for HUD updates
signal party_stats_changed
signal keys_changed(new_count: int)
signal sword_upgraded(new_level: int)

# Party system
var party: Array[Dictionary] = []
var max_party_size: int = 3

# Inventory
var keys: int = 0
var inventory: Dictionary = {
	"healing_potion": 3  # Start with 3 potions
}

# Sword progression
var sword_level: int = 1  # 1, 2, or 3
var sword_damage_bonus: int = 0

# Player state
var current_room: String = "room_0_0"
var player_position: Vector2 = Vector2.ZERO

# Defeated enemies (to prevent respawn)
var defeated_enemies: Dictionary = {}

# Room completion tracking
var unlocked_doors: Array[String] = []

# Collected upgrades tracking
var collected_upgrades: Array[String] = []

func _ready():
	# Initialize default party
	initialize_party()
	update_sword_bonus()

func initialize_party():
	"""Create the starting party members"""
	party.clear()

	# Main character (appears as player in overworld)
	party.append({
		"name": "Hero",
		"level": 1,
		"xp": 0,
		"xp_to_next": 100,
		"max_hp": 30,
		"current_hp": 30,
		"base_str": 8,
		"base_def": 5,
		"base_lck": 6,
		"defending": false
	})

	# Party member 2
	party.append({
		"name": "Warrior",
		"level": 1,
		"xp": 0,
		"xp_to_next": 100,
		"max_hp": 35,
		"current_hp": 35,
		"base_str": 10,
		"base_def": 7,
		"base_lck": 4,
		"defending": false
	})

	# Party member 3
	party.append({
		"name": "Mage",
		"level": 1,
		"xp": 0,
		"xp_to_next": 100,
		"max_hp": 25,
		"current_hp": 25,
		"base_str": 6,
		"base_def": 3,
		"base_lck": 8,
		"defending": false
	})

func get_stat(character: Dictionary, stat_name: String) -> int:
	"""Get the effective stat value for a character (includes sword bonus for STR)"""
	match stat_name:
		"str":
			# Only main character (Hero) gets sword bonus
			if character["name"] == "Hero":
				return character["base_str"] + sword_damage_bonus
			return character["base_str"]
		"def":
			return character["base_def"]
		"lck":
			return character["base_lck"]
		_:
			return 0

func add_xp_to_party(xp_amount: int):
	"""Add XP to all party members and handle level ups"""
	var level_ups: Array[Dictionary] = []

	for character in party:
		character["xp"] += xp_amount

		# Check for level up
		while character["xp"] >= character["xp_to_next"]:
			character["xp"] -= character["xp_to_next"]
			character["level"] += 1
			level_up_character(character)
			level_ups.append(character)

	return level_ups

func level_up_character(character: Dictionary):
	"""Increase stats when leveling up"""
	# Increase stats (simple scaling)
	character["max_hp"] += 5
	character["current_hp"] = character["max_hp"]  # Full heal on level up
	character["base_str"] += 2
	character["base_def"] += 1
	character["base_lck"] += 1

	# Increase XP requirement for next level
	character["xp_to_next"] = int(character["xp_to_next"] * 1.5)

	# Emit signal for HUD update
	party_stats_changed.emit()

func add_key():
	"""Add a key to inventory"""
	keys += 1
	keys_changed.emit(keys)

func use_key() -> bool:
	"""Use a key, returns true if successful"""
	if keys > 0:
		keys -= 1
		keys_changed.emit(keys)
		return true
	return false

func upgrade_sword():
	"""Upgrade the sword to next tier"""
	if sword_level < 3:
		sword_level += 1
		update_sword_bonus()
		sword_upgraded.emit(sword_level)

func update_sword_bonus():
	"""Calculate sword damage bonus based on level"""
	sword_damage_bonus = (sword_level - 1) * 5  # +0, +5, +10

func add_item(item_name: String, amount: int = 1):
	"""Add item to inventory"""
	if inventory.has(item_name):
		inventory[item_name] += amount
	else:
		inventory[item_name] = amount

func use_item(item_name: String) -> bool:
	"""Use an item from inventory, returns true if successful"""
	if inventory.has(item_name) and inventory[item_name] > 0:
		inventory[item_name] -= 1
		return true
	return false

func heal_party_member(index: int, amount: int):
	"""Heal a specific party member"""
	if index >= 0 and index < party.size():
		party[index]["current_hp"] = min(
			party[index]["current_hp"] + amount,
			party[index]["max_hp"]
		)
		party_stats_changed.emit()

func is_party_alive() -> bool:
	"""Check if any party member is still alive"""
	for character in party:
		if character["current_hp"] > 0:
			return true
	return false

func mark_enemy_defeated(room_id: String, enemy_id: String):
	"""Mark an enemy as defeated in a specific room"""
	if not defeated_enemies.has(room_id):
		defeated_enemies[room_id] = []
	if not defeated_enemies[room_id].has(enemy_id):
		defeated_enemies[room_id].append(enemy_id)

func is_enemy_defeated(room_id: String, enemy_id: String) -> bool:
	"""Check if an enemy has been defeated"""
	if defeated_enemies.has(room_id):
		return defeated_enemies[room_id].has(enemy_id)
	return false

func unlock_door(door_id: String):
	"""Mark a door as unlocked"""
	if not unlocked_doors.has(door_id):
		unlocked_doors.append(door_id)

func is_door_unlocked(door_id: String) -> bool:
	"""Check if a door is unlocked"""
	return unlocked_doors.has(door_id)

func mark_upgrade_collected(upgrade_id: String):
	"""Mark an upgrade as collected"""
	if not collected_upgrades.has(upgrade_id):
		collected_upgrades.append(upgrade_id)

func is_upgrade_collected(upgrade_id: String) -> bool:
	"""Check if an upgrade has been collected"""
	return collected_upgrades.has(upgrade_id)
