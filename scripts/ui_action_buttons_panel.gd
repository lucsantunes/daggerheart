extends HBoxContainer

signal action_pressed(action_id)

@onready var roll_button := Button.new()

func _ready():
	# Create a single action button for now: "Tentar Ação"
	roll_button.text = "Tentar Ação"
	roll_button.pressed.connect(_on_roll_pressed)
	add_child(roll_button)
	# Initially disabled; enabled at player turn
	set_buttons_enabled(false)
	print("[ActionButtonsPanel] Ready. Button created.")


func set_buttons_enabled(enabled: bool) -> void:
	for child in get_children():
		if child is Button:
			child.disabled = not enabled
	print("[ActionButtonsPanel] Buttons enabled: %s" % [str(enabled)])


func _on_roll_pressed():
	print("[ActionButtonsPanel] 'Tentar Ação' pressed")
	emit_signal("action_pressed", "attempt_action")


