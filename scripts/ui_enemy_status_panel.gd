extends HBoxContainer

@export var party_path: NodePath
signal enemy_selected(enemy: Node)

var _bound_monsters: Array = []
var _card_to_monster: Dictionary = {}
var _selected_card: VBoxContainer = null


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
				if node and node.has_signal("initialized"):
					# Defer binding until the monster finished _ready and populated data
					node.initialized.connect(func(): _bind_monster(node))
				elif node and node.has_signal("hp_changed"):
					# Backward compatibility if initialized not present
					_bind_monster(node)
			)


func _bind_party(party: Node) -> void:
	for i in party.get_child_count():
		var mc := party.get_child(i)
		if mc:
			if mc.has_signal("initialized"):
				mc.initialized.connect(func(): _bind_monster(mc))
				# It may already be initialized; try immediate bind as well
				_bind_monster(mc)
			elif mc.has_signal("hp_changed"):
				_bind_monster(mc)


func _bind_monster(mc: Node) -> void:
	if _bound_monsters.has(mc):
		return
	# Ensure data exists before creating UI
	var bag: Dictionary = {}
	if mc and mc.has_method("get"):
		var maybe = mc.get("data")
		if typeof(maybe) == TYPE_DICTIONARY:
			bag = maybe
	if bag.is_empty():
		return
	_bound_monsters.append(mc)
	var card := _create_card_for(mc)
	_card_to_monster[card] = mc
	add_child(card)
	# Connect updates
	mc.hp_changed.connect(func(_v): _refresh_card(card, mc))
	if mc.has_signal("defeated"):
		mc.defeated.connect(func():
			# Cleanup card and mappings safely
			if is_instance_valid(card) and card.get_parent() == self:
				remove_child(card)
				card.queue_free()
			if _selected_card == card:
				_selected_card = null
			_card_to_monster.erase(card)
			_bound_monsters.erase(mc)
			_update_selection_highlight()
		)
	print("[EnemyStatusPanel] Bound monster:", str(mc.data.get("name", "?")))
	# Click to select target
	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select_card(card)
			enemy_selected.emit(mc)
	)


func _create_card_for(mc: Node) -> VBoxContainer:
	var card := VBoxContainer.new()
	card.name = "EnemyCard_" + str(mc.data.get("name", "?"))
	card.focus_mode = Control.FOCUS_CLICK
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var name_label := Label.new()
	name_label.text = str(mc.data.get("name", "?"))
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
	var diff := int(mc.data.get("difficulty", 0))
	var weapon := "%s | %s %s" % [
		str(mc.data.get("weapon_name", "?")),
		str(mc.data.get("weapon_roll", "?")),
		str(mc.data.get("weapon_damage_type", "?"))
	]
	var features: Array = mc.data.get("features", [])
	var tags := "; ".join(features)
	meta.text = "Dif %d | %s | %s" % [diff, weapon, tags]
	var mj: int = int(mc.data.get("threshold_major", 0))
	var sv: int = int(mc.data.get("threshold_severe", 0))
	hp.text = "HP %d/%d (M %d S %d)" % [int(mc.current_hp), int(mc.data.get("hp_max", 0)), mj, sv]


func _select_card(card: VBoxContainer) -> void:
	_selected_card = card
	_update_selection_highlight()


func _update_selection_highlight() -> void:
	for c in _card_to_monster.keys():
		if not is_instance_valid(c):
			continue
		if c == _selected_card:
			c.modulate = Color(1, 1, 0.8)
		else:
			c.modulate = Color(1, 1, 1)


