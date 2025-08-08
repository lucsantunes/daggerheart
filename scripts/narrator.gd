extends Node

@onready var chat_log = $"../UI/ChatLog"


func narrate_roll(speaker: String, listener: String, result_type: String, variant: String, values: Dictionary):
	var situation = "roll " + result_type
	var msg = DatabaseVoices.get_line(speaker, listener, situation, variant, values)
	chat_log.add_entry(msg.speaker, msg.text, msg.style)


func narrate_custom(speaker: String, listener: String, situation: String, variant: String, values: Dictionary):
	var msg = DatabaseVoices.get_line(speaker, listener, situation, variant, values)
	chat_log.add_entry(msg.speaker, msg.text, msg.style)
