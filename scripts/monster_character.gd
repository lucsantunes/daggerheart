extends VBoxContainer

# Minimal display + state for a monster instance
@export var monster_id: String = ""

var data: Dictionary = {}
var current_hp: int = 0
var current_stress: int = 0

@onready var name_label := Label.new()
@onready var hp_label := Label.new()
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

	name_label.text = data.name
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(name_label)

	add_child(hp_label)
	_refresh_hp_text()

	tooltip_text = _build_tooltip()
	print("[MonsterCharacter] Spawned:", data.name, " HP:", current_hp)


func _refresh_hp_text():
	var mj: int = int(data.threshold_major)
	var sv: int = int(data.threshold_severe)
	hp_label.text = "HP: %d (major %d, severe %d)" % [current_hp, mj, sv]


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
	_refresh_hp_text()
	print("[MonsterCharacter] %s loses %d HP → %d" % [data.name, units, current_hp])


