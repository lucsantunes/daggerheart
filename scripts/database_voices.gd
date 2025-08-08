extends Node

var voices = {}


func _ready():
	load_csv("res://data/database_voices.csv")


func load_csv(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	file.get_csv_line()
	while not file.eof_reached():
		var row = file.get_csv_line()

		if row.size() < 6:
			continue

		var speaker = row[0]
		var listener = row[1]
		var situation = row[2]
		var variant = row[3]
		var style = row[4]
		var text = row[5]

		var key = "%s|%s|%s|%s" % [speaker, listener, situation, variant]

		if not voices.has(key):
			voices[key] = []

		voices[key].append({"style": style, "text": text})


func get_line(speaker: String, listener: String, situation: String, variant: String, values := {}) -> Dictionary:
	var keys_to_try = []

	keys_to_try.append("%s|%s|%s|%s" % [speaker, listener, situation, variant])
	keys_to_try.append("%s|all|%s|%s" % [speaker, situation, variant])
	keys_to_try.append("%s|all|%s|generic" % [speaker, situation])
	keys_to_try.append("system|all|%s|generic" % situation)

	for key in keys_to_try:
		if voices.has(key):
			values["speaker"] = speaker
			values["listener"] = listener

			var options = voices[key]
			var chosen = options[randi() % options.size()]
			var final_text = chosen.text

			for token in values:
				final_text = final_text.replace("{%s}" % token, str(values[token]))

			return {
				"speaker": speaker,
				"style": chosen.style,
				"text": final_text
			}

	return {
		"speaker": "system",
		"style": "error",
		"text": "%s|%s|%s|%s not found" % [speaker, listener, situation, variant]
	}
