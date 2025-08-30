extends HBoxContainer

func _ready():
	print("[EnemyParty] Ready.")


func spawn_monster(monster_id: String) -> Node:
	var monster := preload("res://scripts/monster_character.gd").new()
	monster.monster_id = monster_id
	add_child(monster)
	print("[EnemyParty] Spawned monster id:", monster_id)
	return monster

