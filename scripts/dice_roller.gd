extends Node

signal duality_rolled(hope_roll: int, fear_roll: int, total: int, result_type: String)
signal d20_rolled(value: int)


func roll_duality(modifier: int = 0) -> void:
	var hope := randi_range(1, 12)
	var fear := randi_range(1, 12)
	var total := hope + modifier
	var result_type := ""

	if fear > hope:
		result_type = "fear"
	elif hope > fear:
		result_type = "hope"
	else:
		result_type = "crit"

	emit_signal("duality_rolled", hope, fear, total, result_type)


func roll_d20(modifier: int = 0) -> void:
	var value := randi_range(1, 20) + modifier
	emit_signal("d20_rolled", value)
