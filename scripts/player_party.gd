extends HBoxContainer

func _ready():
	print("[PlayerParty] Ready.")
	if get_child_count() == 0:
		var PlayerCharacter = preload("res://scripts/player_character.gd")
		# Spawn two players (using default_hero template for both for now)
		var pc1 := PlayerCharacter.new()
		pc1.player_id = "default_hero"
		pc1.render_inline_ui = false
		add_child(pc1)
		print("[PlayerParty] Spawned player id:", pc1.player_id)

		var pc2 := PlayerCharacter.new()
		pc2.player_id = "default_hero"
		pc2.render_inline_ui = false
		add_child(pc2)
		print("[PlayerParty] Spawned player id:", pc2.player_id)


func get_first_alive_player() -> Node:
	for i in get_child_count():
		var c := get_child(i)
		if c and c.has_method("apply_hp_loss"):
			if int(c.current_hp) > 0:
				return c
	return null

