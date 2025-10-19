extends Area2D

# Sword upgrade pickup

@export var upgrade_id: String = "sword_upgrade_1"

var player_nearby: bool = false
var collected: bool = false

func _ready():
	# Check if already collected (could add tracking to GameManager)
	pass

func _process(_delta):
	if player_nearby and Input.is_action_just_pressed("ui_accept") and not collected:
		collect_upgrade()

func collect_upgrade():
	collected = true
	GameManager.upgrade_sword()

	# Show message (would be better with a proper UI popup)
	print("Sword upgraded to level %d!" % GameManager.sword_level)

	# Remove the pickup
	queue_free()

func _on_body_entered(body):
	if body.name == "Player":
		player_nearby = true

func _on_body_exited(body):
	if body.name == "Player":
		player_nearby = false
