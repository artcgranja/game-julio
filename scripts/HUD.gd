extends CanvasLayer

# HUD for displaying player stats in overworld

@onready var hp_label = $Panel/VBoxContainer/HPLabel
@onready var level_label = $Panel/VBoxContainer/LevelLabel
@onready var keys_label = $Panel/VBoxContainer/KeysLabel
@onready var sword_label = $Panel/VBoxContainer/SwordLabel

func _ready():
	update_hud()

func _process(_delta):
	update_hud()

func update_hud():
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
