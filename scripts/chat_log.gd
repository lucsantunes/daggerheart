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
	# Defer autoscroll to ensure layout updates are applied
	call_deferred("_autoscroll_last")


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
		# Wait frames so the ScrollContainer computes correct scroll bounds
		await get_tree().process_frame
		await get_tree().process_frame
		var sc := parent_scroll as ScrollContainer
		var vbar := sc.get_v_scroll_bar()
		if vbar:
			vbar.value = vbar.max_value
			print("[ChatLog] Autoscroll set vbar to bottom (value=%d, max=%d)." % [vbar.value, vbar.max_value])
		var last = get_child(get_child_count() - 1) if get_child_count() > 0 else null
		if last and last is Control:
			sc.ensure_control_visible(last)
			print("[ChatLog] ensure_control_visible(last) called.")
