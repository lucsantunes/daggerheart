extends Node

# Signals describing turn flow events for the combat loop
signal player_turn_started
signal master_turn_started
signal turn_ended

# Public state for current controller
var is_player_turn: bool = true

func _ready():
	# Start with the player by default
	start_player_turn()


func start_player_turn() -> void:
	is_player_turn = true
	emit_signal("player_turn_started")


func end_player_turn() -> void:
	# After player ends (by failure or fear outcome), Master acts
	start_master_turn()


func start_master_turn() -> void:
	is_player_turn = false
	emit_signal("master_turn_started")


func end_master_turn() -> void:
	# After the Master reacts, a new player turn begins
	emit_signal("turn_ended")
	start_player_turn()


