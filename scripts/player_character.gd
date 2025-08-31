extends VBoxContainer

signal hp_changed(current_hp: int)
signal defeated
signal hope_changed(current_hope: int)

@export var player_id: String = ""
@export var render_inline_ui: bool = false

var data: Dictionary = {}
var current_hp: int = 0
var current_stress: int = 0
var current_hope: int = 0

@onready var name_label := Label.new()
@onready var stats_label := Label.new()
@onready var hp_label := Label.new()
@onready var database_players: Node = get_node("/root/DatabasePlayers")


func _ready() -> void:
	if player_id == "":
		push_warning("[PlayerCharacter] player_id not set")
		return

	data = database_players.get_player(player_id)
	if data.is_empty():
		push_error("[PlayerCharacter] Data not found for id: %s" % player_id)
		return

	current_hp = int(data.hp_max)
	current_stress = int(data.stress_max)
	current_hope = 0

	if render_inline_ui:
		name_label.text = data.name
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(name_label)

		stats_label.text = "Evasion: %d | Armor: %d | Hope: %d/%d" % [int(data.evasion), int(data.armor), current_hope, int(data.hope_max)]
		add_child(stats_label)

		add_child(hp_label)
		_refresh_hp_text()

		tooltip_text = _build_tooltip()
	print("[PlayerCharacter] Spawned:", data.name, " HP:", current_hp)


func _refresh_hp_text() -> void:
	var mj: int = int(data.threshold_major)
	var sv: int = int(data.threshold_severe)
	hp_label.text = "HP: %d (major %d, severe %d)" % [current_hp, mj, sv]


func _build_tooltip() -> String:
	var parts: Array = []
	parts.append("Evasion: %d" % int(data.evasion))
	parts.append("Armor: %d" % int(data.armor))
	parts.append("Weapon: %s | %s %s" % [data.weapon_name, data.weapon_roll, data.weapon_damage_type])
	parts.append("Experience: %s +%d" % [data.experience_tag, int(data.experience_bonus)])
	parts.append("Attributes: Agi %d, Str %d, Fin %d, Ins %d, Pre %d, Kno %d" % [
		int(data.agility), int(data.strength), int(data.finesse), int(data.instinct), int(data.presence), int(data.knowledge)
	])
	return "\n".join(parts)


func apply_hp_loss(units: int) -> void:
	current_hp = max(0, current_hp - units)
	_refresh_hp_text()
	emit_signal("hp_changed", current_hp)
	print("[PlayerCharacter] %s loses %d HP → %d" % [data.name, units, current_hp])
	if current_hp <= 0:
		emit_signal("defeated")
		print("[PlayerCharacter] %s defeated." % data.name)


func add_hope(amount: int) -> void:
	var max_hope: int = int(data.hope_max)
	var new_value: int = clamp(current_hope + amount, 0, max_hope)
	if new_value != current_hope:
		current_hope = new_value
		stats_label.text = "Evasion: %d | Armor: %d | Hope: %d/%d" % [int(data.evasion), int(data.armor), current_hope, max_hope]
		emit_signal("hope_changed", current_hope)
		print("[PlayerCharacter] %s gains Hope → %d/%d" % [data.name, current_hope, max_hope])


