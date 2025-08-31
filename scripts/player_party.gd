extends HBoxContainer

func _ready():
	print("[PlayerParty] Ready.")
	if get_child_count() == 0:
		var pc := preload("res://scripts/player_character.gd").new()
		pc.player_id = "default_hero"
		add_child(pc)
		print("[PlayerParty] Spawned player id:", pc.player_id)


func get_first_alive_player() -> Node:
	for i in get_child_count():
		var c := get_child(i)
		if c and c.has_method("apply_hp_loss"):
			if int(c.current_hp) > 0:
				return c
	return null

