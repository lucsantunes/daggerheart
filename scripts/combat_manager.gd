extends Node

# Minimal combat manager to demonstrate effects
signal damage_applied(target_name: String, amount: int, remaining_hp: int)
signal damage_categorized(target_name: String, rolled_damage: int, category: String, hp_loss: int)

var target_hp: int = 10
var target_name: String = "Inimigo"

func _ready():
	print("[CombatManager] Ready. Target: %s, HP: %d" % [target_name, target_hp])


func apply_attempt_outcome(result_type: String) -> void:
	# Simplified effect logic: hope/crit = dano 2, fear = 0 e mestre reage (já tratado no TurnManager)
	match result_type:
		"hope":
			_apply_damage(2)
		"crit":
			_apply_damage(3)
		"fear":
			# Nenhum dano neste protótipo
			print("[CombatManager] Fear outcome. No damage applied.")
			pass
		_:
			print("[CombatManager] Unknown outcome:", result_type)


func resolve_attack(_attacker: Node, target: Node, damage_roll_string: String) -> void:
	# Target is expected to be a MonsterCharacter-like node with fields used below
	if not target or not target.has_method("apply_hp_loss"):
		print("[CombatManager] resolve_attack: invalid target")
		return

	var damage := get_tree().root.get_node("/root/CombatScene/DiceRoller")
	if damage == null:
		print("[CombatManager] DiceRoller not found for resolve_attack")
		return

	var dice_roller := damage
	var rolled: int = int(dice_roller.roll_string(damage_roll_string))
	var breakdown: String = str(rolled)
	if typeof(dice_roller.last_roll_details) == TYPE_DICTIONARY and dice_roller.last_roll_details.has("breakdown"):
		breakdown = String(dice_roller.last_roll_details["breakdown"])

	var major := int(target.data.threshold_major)
	var severe := int(target.data.threshold_severe)
	var category := "minor"
	var hp_loss := 1
	if rolled >= severe:
		category = "severe"
		hp_loss = 3
	elif rolled >= major:
		category = "major"
		hp_loss = 2

	print("[CombatManager] resolve_attack → %s = %d | major: %d, severe: %d → %s (-%d HP)" % [breakdown, rolled, major, severe, category, hp_loss])
	emit_signal("damage_categorized", target.data.name, rolled, category, hp_loss)

	target.apply_hp_loss(hp_loss)
	emit_signal("damage_applied", target.data.name, hp_loss, target.current_hp)


func _apply_damage(amount: int) -> void:
	target_hp = max(0, target_hp - amount)
	print("[CombatManager] Damage: %d → %s, HP: %d" % [amount, target_name, target_hp])
	emit_signal("damage_applied", target_name, amount, target_hp)


