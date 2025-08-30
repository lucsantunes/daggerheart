extends Node

var monsters: Dictionary = {}

func _ready():
	load_csv("res://data/database_monsters.csv")


func load_csv(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("[DatabaseMonsters] ERROR opening:", path)
		return

	var header := file.get_csv_line()
	print("[DatabaseMonsters] Loading:", path)
	print("[DatabaseMonsters] Header:", ", ".join(header))

	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() == 0:
			continue
		if row.size() < 16:
			print("[DatabaseMonsters] Skipping short row:", row)
			continue

		var entry := {
			"id": row[0],
			"type": row[1],
			"name": row[2],
			"difficulty": int(row[3]),
			"attack_bonus": int(row[4]),
			"weapon_name": row[5],
			"weapon_roll": row[6],
			"weapon_damage_type": row[7],
			"experience_tag": row[8],
			"experience_bonus": int(row[9]),
			"motives_tactics": _split_list(row[10], ";"),
			"hp_max": int(row[11]),
			"stress_max": int(row[12]),
			"threshold_major": int(row[13]),
			"threshold_severe": int(row[14]),
			"features": _split_list(row[15], ";")
		}

		monsters[entry.id] = entry
		print("[DatabaseMonsters] Loaded:", entry.id, " -> ", entry.name)

	print("[DatabaseMonsters] Total loaded:", monsters.size())


func _split_list(raw: String, sep: String) -> Array:
	var parts := raw.split(sep)
	var cleaned: Array = []
	for p in parts:
		var t := p.strip_edges()
		if t != "":
			cleaned.append(t)
	return cleaned


func get_monster(id: String) -> Dictionary:
	if monsters.has(id):
		var data: Dictionary = monsters[id]
		print("[DatabaseMonsters] get_monster id:", id, " name:", data.name)
		return data
	print("[DatabaseMonsters] get_monster MISSING:", id)
	return {}


