extends CanvasLayer

# HUD for displaying player stats in overworld

@onready var hp_label = $Panel/VBoxContainer/HPLabel
@onready var level_label = $Panel/VBoxContainer/LevelLabel
@onready var keys_label = $Panel/VBoxContainer/KeysLabel
@onready var sword_label = $Panel/VBoxContainer/SwordLabel

func _ready():
	# Connect to GameManager signals for efficient updates
	GameManager.party_stats_changed.connect(_on_party_stats_changed)
	GameManager.keys_changed.connect(_on_keys_changed)
	GameManager.sword_upgraded.connect(_on_sword_upgraded)

	# Initial update
	update_hud()

func update_hud():
	"""Update all HUD elements"""
	if GameManager.party.is_empty():
		return

	var hero = GameManager.party[0]  # Main character

	if hp_label:
		hp_label.text = "HP: %d/%d" % [hero["current_hp"], hero["max_hp"]]

	if level_label:
		level_label.text = "Level: %d" % hero["level"]

	if keys_label:
		keys_label.text = "Keys: %d" % GameManager.keys

	if sword_label:
		sword_label.text = "Sword: Level %d" % GameManager.sword_level

func _on_party_stats_changed():
	"""Update when party stats change (HP, level, etc.)"""
	update_hud()

func _on_keys_changed(_new_count: int):
	"""Update when key count changes"""
	if keys_label:
		keys_label.text = "Keys: %d" % GameManager.keys

func _on_sword_upgraded(_new_level: int):
	"""Update when sword is upgraded"""
	if sword_label:
		sword_label.text = "Sword: Level %d" % GameManager.sword_level
