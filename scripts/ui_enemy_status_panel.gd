extends HBoxContainer

@export var party_path: NodePath

var _bound_monsters: Array = []


func _ready() -> void:
	print("[EnemyStatusPanel] Ready.")
	var party: Node = null
	if party_path != NodePath():
		party = get_node_or_null(party_path)
		if not party:
			print("[EnemyStatusPanel] Party path not found:", party_path)
	else:
		# Default path used by CombatScene
		party = get_node_or_null("../EnemyParty")

	if party:
		_bind_party(party)
		# Bind future spawns
		if party.has_signal("child_entered_tree"):
			party.child_entered_tree.connect(func(node: Node):
				if node and node.has_signal("hp_changed"):
					_bind_monster(node)
			)


func _bind_party(party: Node) -> void:
	for i in party.get_child_count():
		var mc := party.get_child(i)
		if mc and mc.has_signal("hp_changed"):
			_bind_monster(mc)


func _bind_monster(mc: Node) -> void:
	if _bound_monsters.has(mc):
		return
	_bound_monsters.append(mc)
	var card := _create_card_for(mc)
	add_child(card)
	# Connect updates
	mc.hp_changed.connect(func(_v): _refresh_card(card, mc))
	print("[EnemyStatusPanel] Bound monster:", mc.data.name)


func _create_card_for(mc: Node) -> VBoxContainer:
	var card := VBoxContainer.new()
	card.name = "EnemyCard_" + mc.data.name
	var name_label := Label.new()
	name_label.text = mc.data.name
	var meta := Label.new()
	meta.name = "Meta"
	var hp := Label.new()
	hp.name = "HP"
	card.add_child(name_label)
	card.add_child(meta)
	card.add_child(hp)
	_refresh_card(card, mc)
	return card


func _refresh_card(card: VBoxContainer, mc: Node) -> void:
	var meta: Label = card.get_node("Meta")
	var hp: Label = card.get_node("HP")
	# Show key monster info for combat readability
	var diff := int(mc.data.difficulty)
	var weapon := "%s | %s %s" % [mc.data.weapon_name, mc.data.weapon_roll, mc.data.weapon_damage_type]
	var tags := "; ".join(mc.data.features)
	meta.text = "Dif %d | %s | %s" % [diff, weapon, tags]
	var mj: int = int(mc.data.threshold_major)
	var sv: int = int(mc.data.threshold_severe)
	hp.text = "HP %d/%d (M %d S %d)" % [int(mc.current_hp), int(mc.data.hp_max), mj, sv]


