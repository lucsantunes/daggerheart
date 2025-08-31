extends HBoxContainer

@export var party_path: NodePath

var _bound_players: Array = []


func _ready() -> void:
	print("[PlayerStatusPanel] Ready.")
	if party_path != NodePath():
		var party := get_node_or_null(party_path)
		if party:
			_bind_party(party)
		else:
			print("[PlayerStatusPanel] Party path not found:", party_path)
	else:
		# Default path used by CombatScene
		var default_party := get_node_or_null("../PlayerParty")
		if default_party:
			_bind_party(default_party)


func _bind_party(party: Node) -> void:
	# Bind existing children
	for i in party.get_child_count():
		var pc := party.get_child(i)
		if pc and pc.has_signal("hp_changed"):
			_bind_player(pc)


func _bind_player(pc: Node) -> void:
	if _bound_players.has(pc):
		return
	_bound_players.append(pc)
	# Build a small card UI for this player
	var card := _create_card_for(pc)
	add_child(card)

	# Connect updates
	pc.hp_changed.connect(func(_v): _refresh_card(card, pc))
	if pc.has_signal("hope_changed"):
		pc.hope_changed.connect(func(_v): _refresh_card(card, pc))

	print("[PlayerStatusPanel] Bound player:", pc.data.name)


func _create_card_for(pc: Node) -> VBoxContainer:
	var card := VBoxContainer.new()
	card.name = "Card_" + pc.data.name
	var name_label := Label.new()
	name_label.text = pc.data.name
	var stats := Label.new()
	stats.name = "Stats"
	var hp := Label.new()
	hp.name = "HP"
	card.add_child(name_label)
	card.add_child(stats)
	card.add_child(hp)
	_refresh_card(card, pc)
	return card


func _refresh_card(card: VBoxContainer, pc: Node) -> void:
	var stats: Label = card.get_node("Stats")
	var hp: Label = card.get_node("HP")
	var ev := int(pc.data.evasion)
	var ar := int(pc.data.armor)
	var hope_max := int(pc.data.hope_max)
	var hope_val := int(pc.current_hope) if pc.has_method("add_hope") else 0
	stats.text = "Evasion %d | Armor %d | Hope %d/%d | Stress %d/%d" % [
		ev, ar, hope_val, hope_max, int(pc.current_stress), int(pc.data.stress_max)
	]
	var mj: int = int(pc.data.threshold_major)
	var sv: int = int(pc.data.threshold_severe)
	hp.text = "HP %d/%d (M %d S %d)" % [int(pc.current_hp), int(pc.data.hp_max), mj, sv]


