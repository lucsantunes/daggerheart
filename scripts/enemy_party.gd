extends HBoxContainer

func _ready():
	print("[EnemyParty] Ready.")
	# Spawn two monsters by default if empty
	if get_child_count() == 0:
		spawn_monster("jagged_knife_bandit")
		spawn_monster("jagged_knife_bandit")


func spawn_monster(monster_id: String) -> Node:
	var monster := preload("res://scripts/monster_character.gd").new()
	monster.monster_id = monster_id
	add_child(monster)
	print("[EnemyParty] Spawned monster id:", monster_id)
	return monster


func get_first_alive_monster() -> Node:
	for i in get_child_count():
		var c := get_child(i)
		if c and c.has_method("apply_hp_loss"):
			if int(c.current_hp) > 0:
				return c
	return null

