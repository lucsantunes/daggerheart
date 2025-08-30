extends Node2D

@onready var dice_roller = $DiceRoller
@onready var chat_log = $UI/ChatLog
@onready var narrator = $Narrator
@onready var turn_manager = $TurnManager
@onready var action_panel = $UI/ActionButtonsPanel
@onready var combat_manager = $CombatManager
@onready var enemy_party = $UI/EnemyParty
@onready var player_party = $UI/PlayerParty


func _ready():
	# Connect signals
	dice_roller.duality_rolled.connect(_on_duality_rolled)
	turn_manager.player_turn_started.connect(_on_player_turn_started)
	turn_manager.master_turn_started.connect(_on_master_turn_started)
	action_panel.action_pressed.connect(_on_action_pressed)
	combat_manager.damage_applied.connect(_on_damage_applied)

	# Opening message
	chat_log.add_entry("Sistema", "O combate começou!", "narration")
	print("[CombatScene] Ready. Signals connected.")
	# Ensure we start AFTER connections are made
	turn_manager.start_player_turn()

	# Spawn initial enemy (Bandit)
	enemy_party.spawn_monster("jagged_knife_bandit")

func _on_player_turn_started() -> void:
	action_panel.set_buttons_enabled(true)
	chat_log.add_entry("Sistema", "Sua vez. Escolha uma ação.", "narration")
	print("[CombatScene] Player turn started. UI enabled.")


func _on_master_turn_started() -> void:
	action_panel.set_buttons_enabled(false)
	chat_log.add_entry("Mestre", "Eu reajo às suas escolhas...", "effect")
	# For now, Master just ends its turn immediately
	print("[CombatScene] Master turn started. Reacting and ending.")
	turn_manager.end_master_turn()


func _on_action_pressed(action_id: String) -> void:
	if action_id == "attempt_action":
		# Perform the core Daggerheart duality roll to resolve the attempt
		print("[CombatScene] Action pressed: %s" % [action_id])
		dice_roller.roll_duality(0)


func _on_duality_rolled(hope_roll: int, fear_roll: int, total: int, result_type: String) -> void:
	# Map result for narration keys
	var mapped := result_type
	if result_type == "crit":
		mapped = "tie"

	# Narrate the roll outcome using data-driven lines
	narrator.narrate_roll("system", "all", mapped, "generic", {
		"hope": hope_roll,
		"fear": fear_roll,
		"total": total
	})

	# Turn flow: player continues on hope or crit; master reacts on fear
	if result_type == "fear":
		print("[CombatScene] Fear outcome. Passing turn to Master.")
		turn_manager.end_player_turn()
	else:
		print("[CombatScene] Hope or Crit. Player may act again.")
		chat_log.add_entry("Sistema", "Você pode agir novamente.", "narration")

	# Apply simplified combat effects
	combat_manager.apply_attempt_outcome(result_type)


func _on_damage_applied(target_name: String, amount: int, remaining_hp: int) -> void:
	print("[CombatScene] Damage applied: %d to %s, remaining HP: %d" % [amount, target_name, remaining_hp])
	narrator.narrate_custom("system", "all", "damage dealt", "generic", {
		"target": target_name,
		"amount": amount,
		"hp": remaining_hp
	})
