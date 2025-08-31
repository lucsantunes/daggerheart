extends VBoxContainer

# Minimal display + state for a monster instance
signal hp_changed(value: int)
@export var monster_id: String = ""

var data: Dictionary = {}
var current_hp: int = 0
var current_stress: int = 0

@onready var database_monsters: Node = get_node("/root/DatabaseMonsters")

func _ready():
	if monster_id == "":
		push_warning("[MonsterCharacter] monster_id not set")
		return

	data = database_monsters.get_monster(monster_id)
	if data.is_empty():
		push_error("[MonsterCharacter] Data not found for id: %s" % monster_id)
		return

	current_hp = data.hp_max
	current_stress = data.stress_max

	# Visual rendering moved to EnemyStatusPanel; keep tooltip for debugging/inspection
	tooltip_text = _build_tooltip()
	print("[MonsterCharacter] Spawned:", data.name, " HP:", current_hp)


func _build_tooltip() -> String:
	var parts: Array = []
	parts.append("Difficulty: %d" % data.difficulty)
	parts.append("Attack: +%d" % data.attack_bonus)
	parts.append("Weapon: %s | %s %s" % [data.weapon_name, data.weapon_roll, data.weapon_damage_type])
	parts.append("Experience: %s +%d" % [data.experience_tag, data.experience_bonus])
	parts.append("Motives/Tactics: %s" % ", ".join(data.motives_tactics))
	parts.append("Features: %s" % "; ".join(data.features))
	return "\n".join(parts)


func apply_hp_loss(units: int) -> void:
	current_hp = max(0, current_hp - units)
	hp_changed.emit(current_hp)
	print("[MonsterCharacter] %s loses %d HP → %d" % [data.name, units, current_hp])


