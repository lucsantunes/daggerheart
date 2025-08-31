extends Node

var players: Dictionary = {}


func _ready():
	load_csv("res://data/database_players.csv")


func load_csv(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("[DatabasePlayers] ERROR opening: %s" % [path])
		return

	var _header := file.get_csv_line()
	print("[DatabasePlayers] Loading: %s" % [path])

	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() == 0:
			continue
		if row.size() < 24:
			continue

		var entry := {
			"id": row[0],
			"name": row[1],
			"evasion": int(row[2]),
			"armor": int(row[3]),
			"hp_max": int(row[4]),
			"stress_max": int(row[5]),
			"threshold_major": int(row[6]),
			"threshold_severe": int(row[7]),
			"agility": int(row[8]),
			"strength": int(row[9]),
			"finesse": int(row[10]),
			"instinct": int(row[11]),
			"presence": int(row[12]),
			"knowledge": int(row[13]),
			"hope_max": int(row[14]),
			"experience_tag": row[15],
			"experience_bonus": int(row[16]),
			"weapon_name": row[17],
			"weapon_roll": row[18],
			"weapon_damage_type": row[19],
			"armor_name": row[20],
			"armor_evasion_bonus": int(row[21]),
			"armor_armor_bonus": int(row[22]),
			"gold": int(row[23])
		}

		players[entry.id] = entry
		print("[DatabasePlayers] Loaded: %s -> %s" % [entry.id, entry.name])

	print("[DatabasePlayers] Total loaded: %d" % [players.size()])


func get_player(id: String) -> Dictionary:
	if players.has(id):
		var data: Dictionary = players[id]
		print("[DatabasePlayers] get_player id: %s, name: %s" % [id, data.name])
		return data
	print("[DatabasePlayers] get_player MISSING: %s" % [id])
	return {}


