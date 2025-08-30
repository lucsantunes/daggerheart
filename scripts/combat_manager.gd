extends Node

# Minimal combat manager to demonstrate effects
signal damage_applied(target_name: String, amount: int, remaining_hp: int)

var target_hp: int = 10
var target_name: String = "Inimigo"

func _ready():
	print("[CombatManager] Ready. Target:", target_name, " HP:", target_hp)


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


func _apply_damage(amount: int) -> void:
	target_hp = max(0, target_hp - amount)
	print("[CombatManager] Damage:", amount, " →", target_name, " HP:", target_hp)
	emit_signal("damage_applied", target_name, amount, target_hp)


