extends Node

# Signals describing turn flow events for the combat loop
signal player_turn_started
signal master_turn_started
signal turn_ended

# Public state for current controller
var is_player_turn: bool = true


func start_player_turn() -> void:
	is_player_turn = true
	print("[TurnManager] Player turn started")
	emit_signal("player_turn_started")


func end_player_turn() -> void:
	# After player ends (by failure or fear outcome), Master acts
	print("[TurnManager] Player turn ended → Master turn")
	start_master_turn()


func start_master_turn() -> void:
	is_player_turn = false
	print("[TurnManager] Master turn started")
	emit_signal("master_turn_started")


func end_master_turn() -> void:
	# After the Master reacts, a new player turn begins
	print("[TurnManager] Master turn ended → Next round")
	emit_signal("turn_ended")
	start_player_turn()


