extends HBoxContainer

@onready var label := Label.new()


func _ready() -> void:
	label.text = "Medo: 0/12"
	add_child(label)
	print("[MasterStatusBox] Ready. Fear display initialized.")


func set_fear(value: int) -> void:
	label.text = "Medo: %d/12" % value
	print("[MasterStatusBox] Fear updated → %d/12" % value)


