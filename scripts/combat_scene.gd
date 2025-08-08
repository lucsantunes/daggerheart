extends Node2D

@onready var dice_roller = $DiceRoller
@onready var chat_log = $UI/ChatLog
@onready var narrator = $Narrator


func _ready():
	# dice_roller.duality_rolled.connect(_on_duality_rolled)
	# dice_roller.d20_rolled.connect(_on_d20_rolled)

	chat_log.add_entry("Sistema", "O combate começou!", "narration")
	chat_log.add_entry("Aurora", "Eles estão vindo!", "talk")
	chat_log.add_entry("Mestre", "O medo se espalha...", "effect")
	chat_log.add_entry("BUG", "ERROR404", "error")
	narrator.narrate_roll('a', 'a', 'fear', 'a', {'fear':7, 'banana':'oi'})
