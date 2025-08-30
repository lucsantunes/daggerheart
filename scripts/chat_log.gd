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
	_autoscroll_last()


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


func _autoscroll_last() -> void:
	var parent_scroll := get_parent()
	if parent_scroll and parent_scroll is ScrollContainer:
		# Wait one frame to ensure layout/size updates are applied before scrolling
		await get_tree().process_frame
		var vbar := (parent_scroll as ScrollContainer).get_v_scroll_bar()
		if vbar:
			vbar.value = vbar.max_value
			print("[ChatLog] Autoscroll to bottom (value=%d, max=%d)." % [vbar.value, vbar.max_value])
