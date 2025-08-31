extends HBoxContainer

@export var party_path: NodePath
signal player_selected(player: Node)

var _bound_players: Array = []
var _card_to_player: Dictionary = {}
var _selected_card: VBoxContainer = null


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
	# Bind future spawns
	if party.has_signal("child_entered_tree"):
		party.child_entered_tree.connect(func(node: Node):
			if node and node.has_signal("hp_changed"):
				_bind_player(node)
		)


func _bind_player(pc: Node) -> void:
	if _bound_players.has(pc):
		return
	_bound_players.append(pc)
	# Build a small card UI for this player
	var card := _create_card_for(pc)
	_card_to_player[card] = pc
	add_child(card)

	# Connect updates
	pc.hp_changed.connect(func(_v): _refresh_card(card, pc))
	if pc.has_signal("hope_changed"):
		pc.hope_changed.connect(func(_v): _refresh_card(card, pc))
	if pc.has_signal("defeated"):
		pc.defeated.connect(func():
			# Cleanup card and mappings safely
			if is_instance_valid(card) and card.get_parent() == self:
				remove_child(card)
				card.queue_free()
			if _selected_card == card:
				_selected_card = null
			_card_to_player.erase(card)
			_bound_players.erase(pc)
			_update_selection_highlight()
		)
	# Click to select acting player
	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select_card(card)
			player_selected.emit(pc)
	)

	print("[PlayerStatusPanel] Bound player:", pc.data.name)


func _create_card_for(pc: Node) -> VBoxContainer:
	var card := VBoxContainer.new()
	card.name = "Card_" + pc.data.name
	card.focus_mode = Control.FOCUS_CLICK
	card.mouse_filter = Control.MOUSE_FILTER_STOP
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
	# Selection style
	if _selected_card == card:
		card.modulate = Color(0.8, 1, 0.8)
	else:
		card.modulate = Color(1, 1, 1)


func _select_card(card: VBoxContainer) -> void:
	_selected_card = card
	_update_selection_highlight()


func _update_selection_highlight() -> void:
	for c in _card_to_player.keys():
		if not is_instance_valid(c):
			continue
		if c == _selected_card:
			c.modulate = Color(0.8, 1, 0.8)
		else:
			c.modulate = Color(1, 1, 1)


