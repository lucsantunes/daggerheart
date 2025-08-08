extends VBoxContainer
signal message_added(message_data)

var messages: Array = []


func add_entry(speaker: String, text: String, style: String) -> void:
	var message = {
		"speaker": speaker,
		"text": text,
		"style": style
	}
	messages.append(message)
	_render_message(message)
	emit_signal("message_added", message)


func _render_message(message: Dictionary) -> void:
	var label := RichTextLabel.new()
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	match message.style:
		"talk":
			label.text = "[%s] %s" % [message.speaker, message.text]

		"narration":
			label.text = "#%s# %s" % [message.speaker, message.text]

		"effect":
			label.text = "!%s! %s" % [message.speaker, message.text]

		_:
			label.text = "%s: %s" % [message.speaker, message.text]

	add_child(label)
