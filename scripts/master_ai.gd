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

	# Announce intent only; do not roll damage before hit check
	if chat_log and chat_log.has_method("add_entry"):
		chat_log.add_entry("Mestre", "%s prepara %s..." % [monster_name, weapon_name], "narration")

		# If player target exists and combat manager provided, perform to-hit check then damage
		if player_party and combat_manager and player_party.has_method("get_first_alive_player"):
			var player_target: Node = player_party.get_first_alive_player()
			if player_target:
				# To-hit: 1d20 + attack_bonus vs player evasion
				var attack_bonus: int = 0
				if typeof(monster) == TYPE_OBJECT and typeof(monster.data) == TYPE_DICTIONARY and monster.data.has("attack_bonus"):
					attack_bonus = int(monster.data.attack_bonus)
				var to_hit: int = 0
				if dice_roller and dice_roller.has_method("roll_d20_value"):
					to_hit = int(dice_roller.roll_d20_value(attack_bonus))
				else:
					to_hit = randi_range(1, 20) + attack_bonus
				print("[MasterAI] To-Hit roll: d20 + %d = %d vs evasion %d" % [attack_bonus, to_hit, int(player_target.data.evasion)])
				var hit := to_hit >= int(player_target.data.evasion)
				if chat_log and chat_log.has_method("add_entry"):
					var ev := int(player_target.data.evasion)
					var outcome := ("ACERTO" if hit else "ERRO")
					chat_log.add_entry("Mestre", "Teste de acerto: d20 + %d = %d vs Evasão %d → %s" % [attack_bonus, to_hit, ev, outcome], "narration")
				if hit:
					print("[MasterAI] HIT. Resolving damage into %s" % player_target.data.name)
					combat_manager.resolve_attack(monster, player_target, weapon_roll)
				else:
					print("[MasterAI] MISS against %s" % player_target.data.name)
	else:
		print("[MasterAI] DiceRoller not available; cannot roll damage.")

	if chat_log and chat_log.has_method("add_entry"):
		chat_log.add_entry("Mestre", "Meu turno termina.", "narration")
	print("[MasterAI] Turn finished.")
	emit_signal("turn_finished")


