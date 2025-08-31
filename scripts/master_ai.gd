extends Node

# Tracks the Master's Fear resource and performs simple reactions on the Master's turn
signal fear_changed(new_value: int)
signal turn_finished

var fear_count: int = 0


func add_fear(amount: int) -> void:
	fear_count = clamp(fear_count + amount, 0, 12)
	print("[MasterAI] Fear increased by %d → %d/12" % [amount, fear_count])
	emit_signal("fear_changed", fear_count)


func take_turn(enemy_party: Node, dice_roller: Node, chat_log: Node, player_party: Node = null, combat_manager: Node = null) -> void:
	print("[MasterAI] Taking turn.")
	if chat_log and chat_log.has_method("add_entry"):
		chat_log.add_entry("Mestre", "O Mestre toma uma ação de reação...", "effect")

	var monster: Node = null
	if enemy_party and enemy_party.get_child_count() > 0:
		monster = enemy_party.get_child(0)

	if monster == null:
		print("[MasterAI] No monsters available. Ending turn.")
		if chat_log and chat_log.has_method("add_entry"):
			chat_log.add_entry("Mestre", "Nenhum monstro disponível. O Mestre observa.", "narration")
		emit_signal("turn_finished")
		return

	var weapon_roll := "1d6"
	var weapon_name := "Ataque"
	var monster_name := "Monstro"
	if typeof(monster) == TYPE_OBJECT:
		# Identify MonsterCharacter by presence of method and read its data bag
		if monster.has_method("apply_hp_loss"):
			if typeof(monster.data) == TYPE_DICTIONARY:
				if monster.data.has("weapon_roll"):
					weapon_roll = String(monster.data.weapon_roll)
				if monster.data.has("weapon_name"):
					weapon_name = String(monster.data.weapon_name)
				if monster.data.has("name"):
					monster_name = String(monster.data.name)

	var total := 0
	if dice_roller and dice_roller.has_method("roll_string"):
		total = int(dice_roller.roll_string(weapon_roll))
		var breakdown := str(total)
		if typeof(dice_roller.last_roll_details) == TYPE_DICTIONARY and dice_roller.last_roll_details.has("breakdown"):
			breakdown = str(dice_roller.last_roll_details["breakdown"])
		print("[MasterAI] %s orders %s to strike (%s = %d)" % [monster_name, weapon_name, breakdown, total])
		if chat_log and chat_log.has_method("add_entry"):
			chat_log.add_entry("Mestre", "%s ataca com %s (%s = %d)" % [monster_name, weapon_name, breakdown, total], "effect")

		# If player target exists and combat manager provided, resolve attack into player
		if player_party and combat_manager and player_party.has_method("get_first_alive_player"):
			var player_target: Node = player_party.get_first_alive_player()
			if player_target:
				print("[MasterAI] Resolving monster attack into player target: %s" % player_target.data.name)
				combat_manager.resolve_attack(monster, player_target, weapon_roll)
	else:
		print("[MasterAI] DiceRoller not available; cannot roll damage.")

	if chat_log and chat_log.has_method("add_entry"):
		chat_log.add_entry("Mestre", "Meu turno termina.", "narration")
	print("[MasterAI] Turn finished.")
	emit_signal("turn_finished")


