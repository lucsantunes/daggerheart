extends Node

signal duality_rolled(hope_roll: int, fear_roll: int, total: int, result_type: String)
signal d20_rolled(value: int)

var last_roll_details: Dictionary = {}

func roll_duality(modifier: int = 0) -> void:
	var hope := randi_range(1, 12)
	var fear := randi_range(1, 12)
	var total := hope + fear + modifier
	var result_type := ""
	print("[DiceRoller] Duality roll → hope: %d, fear: %d, modifier: %d" % [hope, fear, modifier])

	if fear > hope:
		result_type = "fear"
	elif hope > fear:
		result_type = "hope"
	else:
		result_type = "crit"

	print("[DiceRoller] Duality result → %s, total: %d" % [result_type, total])
	emit_signal("duality_rolled", hope, fear, total, result_type)


func roll_d20(modifier: int = 0) -> void:
	var value := randi_range(1, 20) + modifier
	print("[DiceRoller] d20 → %d" % [value])
	emit_signal("d20_rolled", value)


func roll_string(expr: String) -> int:
	# Supports forms like "d8", "1d8", "2d6+3", "3d10-1"
	var trimmed := expr.strip_edges()
	if not trimmed.contains("d"):
		var fallback := int(trimmed)
		print("[DiceRoller] roll_string '%s' → %d (no 'd' found)" % [expr, fallback])
		return fallback

	var dice_and_rest := trimmed.split("d", false)
	var num_dice := 1
	if dice_and_rest[0] != "":
		num_dice = int(dice_and_rest[0])

	var rest := String(dice_and_rest[1])
	var modifier := 0
	var sides_str := rest
	var plus_idx := rest.find("+")
	var minus_idx := rest.find("-")
	var split_idx := -1
	if plus_idx != -1 and minus_idx != -1:
		split_idx = min(plus_idx, minus_idx)
	elif plus_idx != -1:
		split_idx = plus_idx
	elif minus_idx != -1:
		split_idx = minus_idx

	if split_idx != -1:
		sides_str = rest.substr(0, split_idx)
		modifier = int(rest.substr(split_idx, rest.length() - split_idx))

	var sides := int(sides_str)
	var total := 0
	var rolls: Array = []
	for i in num_dice:
		var r := randi_range(1, sides)
		rolls.append(r)
		total += r
	var final_total := total + modifier
	var sum_str := "+".join(rolls.map(func(v): return str(v)))
	var breakdown := sum_str
	if modifier != 0:
		var mod_sign := "+" if modifier > 0 else ""
		breakdown = "%s %s %d" % [sum_str, mod_sign, modifier]
	print("[DiceRoller] roll_string '%s' → %s = %d" % [expr, breakdown, final_total])
	last_roll_details = {
		"expr": trimmed,
		"num_dice": num_dice,
		"sides": sides,
		"rolls": rolls,
		"modifier": modifier,
		"total": final_total,
		"breakdown": breakdown
	}
	return final_total
