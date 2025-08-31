extends Node2D

@onready var dice_roller = $DiceRoller
@onready var chat_log = $UI/ChatScroll/ChatLog
@onready var narrator = $Narrator
@onready var turn_manager = $TurnManager
@onready var action_panel = $UI/ActionButtonsPanel
@onready var combat_manager = $CombatManager
@onready var enemy_party = $UI/EnemyParty
@onready var player_party = $UI/PlayerParty
@onready var master_ai = $MasterAI
@onready var master_status_box = $UI/MasterStatusBox
@onready var enemy_status_panel = $UI/EnemyStatusPanel
@onready var player_status_panel = $UI/PlayerStatusPanel
var current_target: Node = null
var current_actor: Node = null


func _ready():
	# Connect signals
	dice_roller.duality_rolled.connect(_on_duality_rolled)
	turn_manager.player_turn_started.connect(_on_player_turn_started)
	turn_manager.master_turn_started.connect(_on_master_turn_started)
	action_panel.action_pressed.connect(_on_action_pressed)
	combat_manager.damage_applied.connect(_on_damage_applied)
	combat_manager.damage_categorized.connect(_on_damage_categorized)
	master_ai.fear_changed.connect(_on_master_fear_changed)
	master_ai.turn_finished.connect(_on_master_turn_finished)
	# Selection signals from UI panels
	if enemy_status_panel and enemy_status_panel.has_signal("enemy_selected"):
		enemy_status_panel.enemy_selected.connect(func(enemy: Node):
			if enemy and enemy.has_method("apply_hp_loss"):
				current_target = enemy
				print("[CombatScene] Target selected:", enemy.data.name)
				# Clear target if it gets defeated or freed
				if enemy.has_signal("defeated"):
					enemy.defeated.connect(func():
						if current_target == enemy:
							current_target = null
							print("[CombatScene] Cleared target (defeated).")
					)
		)
	if player_status_panel and player_status_panel.has_signal("player_selected"):
		player_status_panel.player_selected.connect(func(pc: Node):
			if pc and pc.has_method("apply_hp_loss"):
				current_actor = pc
				print("[CombatScene] Actor selected:", pc.data.name)
				# Enable actions when a player (actor) is selected
				action_panel.set_buttons_enabled(true)
				# Clear actor and disable if it gets defeated or freed
				if pc.has_signal("defeated"):
					pc.defeated.connect(func():
						if current_actor == pc:
							current_actor = null
							action_panel.set_buttons_enabled(false)
							print("[CombatScene] Cleared actor (defeated).")
					)
		)

	# Opening message
	chat_log.add_entry("Sistema", "O combate começou!", "narration")
	print("[CombatScene] Ready. Signals connected.")
	# Ensure we start AFTER connections are made
	turn_manager.start_player_turn()

	# No seleção inicial automática; o jogador deve clicar para escolher ator/alvo
	current_target = null
	current_actor = null

func _on_player_turn_started() -> void:
	# Habilita o botão somente se houver ator selecionado
	var enable_actions := (current_actor != null and is_instance_valid(current_actor))
	action_panel.set_buttons_enabled(enable_actions)
	chat_log.add_entry("Sistema", "Sua vez. Selecione um herói e um alvo, então ataque.", "narration")
	print("[CombatScene] Player turn started. UI set enabled=%s." % [str(enable_actions)])


func _on_master_turn_started() -> void:
	action_panel.set_buttons_enabled(false)
	chat_log.add_entry("Mestre", "Eu reajo às suas escolhas...", "effect")
	print("[CombatScene] Master turn started. Delegating to MasterAI.")
	master_ai.take_turn(enemy_party, dice_roller, chat_log, player_party, combat_manager)


func _on_action_pressed(action_id: String) -> void:
	if action_id == "attempt_action":
		# Validate selections
		if current_actor == null or not is_instance_valid(current_actor):
			chat_log.add_entry("Sistema", "Selecione um herói para agir.", "narration")
			# Segurança extra: manter botão desabilitado até selecionar um ator
			action_panel.set_buttons_enabled(false)
			return
		if current_target == null or not is_instance_valid(current_target):
			chat_log.add_entry("Sistema", "Selecione um alvo para atacar.", "narration")
			return
		# Perform the core Daggerheart duality roll to resolve the attempt
		print("[CombatScene] Action pressed: %s by %s vs %s" % [action_id, current_actor.data.name, current_target.data.name])
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
	# Narrate breakdown "hope + fear = total"
	narrator.narrate_custom("system", "all", "roll breakdown", "generic", {
		"hope": hope_roll,
		"fear": fear_roll,
		"total": total
	})

	# Guard targets that can be gone mid-resolution
	if current_target == null or not is_instance_valid(current_target):
		print("[CombatScene] No valid target at resolution time.")
		return

	# Hit check against current target difficulty
	var hit_success := false
	if current_target != null:
		var target_diff: int = int(current_target.data.difficulty)
		hit_success = total >= target_diff
		narrator.narrate_custom("system", "all", "attack check", "generic", {
			"total": total,
			"difficulty": target_diff,
			"result": ("HIT" if hit_success else "MISS")
		})

	# Determine if turn should end after resolving action (Fear or Miss)
	var should_end_after := (result_type == "fear") or (not hit_success)

	# Resolve attack only if hit
	if hit_success:
		if current_target != null:
			combat_manager.resolve_attack(current_actor, current_target, "2d8")
			# Narrate the raw damage roll context for clarity
			var mj: int = int(current_target.data.threshold_major)
			var sv: int = int(current_target.data.threshold_severe)
			narrator.narrate_custom("system", "all", "damage roll", "generic", {
				"target": current_target.data.name,
				"major": mj,
				"severe": sv
			})
		else:
			print("[CombatScene] No target to attack.")

	# End or continue turn based on outcome
	if should_end_after:
		if result_type == "fear":
			print("[CombatScene] Fear outcome. Incrementing Master Fear and ending turn.")
			master_ai.add_fear(1)
		else:
			print("[CombatScene] Miss. Ending player turn.")
		turn_manager.end_player_turn()
	else:
		print("[CombatScene] Hope or Crit with hit. Player may act again.")
		chat_log.add_entry("Sistema", "Você pode agir novamente.", "narration")

	# Hope resource gain for player (once per action outcome)
	if result_type == "hope":
		var pc: Node = current_actor if current_actor and current_actor.has_method("add_hope") else null
		if pc:
			pc.add_hope(1)
			print("[CombatScene] Player gains Hope from hope outcome.")


func _on_damage_applied(target_name: String, amount: int, remaining_hp: int) -> void:
	print("[CombatScene] Damage applied: %d to %s, remaining HP: %d" % [amount, target_name, remaining_hp])
	narrator.narrate_custom("system", "all", "damage dealt", "generic", {
		"target": target_name,
		"amount": amount,
		"hp": remaining_hp
	})


func _on_damage_categorized(target_name: String, rolled_damage: int, category: String, hp_loss: int, breakdown: String) -> void:
	print("[CombatScene] Damage category → target: %s, rolled: %d (%s), category: %s, hp_loss: %d" % [target_name, rolled_damage, breakdown, category, hp_loss])
	narrator.narrate_custom("system", "all", "damage categorized", "generic", {
		"target": target_name,
		"rolled": rolled_damage,
		"category": category,
		"hp_loss": hp_loss,
		"breakdown": breakdown
	})


func _on_master_fear_changed(value: int) -> void:
	if master_status_box and master_status_box.has_method("set_fear"):
		master_status_box.set_fear(value)
	print("[CombatScene] UI updated with Master Fear: %d/12" % value)


func _on_master_turn_finished() -> void:
	print("[CombatScene] MasterAI signaled end of turn.")
	turn_manager.end_master_turn()
