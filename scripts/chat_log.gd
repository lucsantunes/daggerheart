extends VBoxContainer
signal message_added(message_data)

var messages: Array = []
var _autoscroll_running: bool = false
var _last_autoscroll_seen_count: int = -1


func add_entry(speaker: String, text: String, style: String) -> void:
	var message = {
		"speaker": speaker,
		"text": text,
		"style": style
	}
	messages.append(message)
	_render_message(message)
	emit_signal("message_added", message)
	# Debounced autoscroll: schedule once per burst
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
	if not (parent_scroll and parent_scroll is ScrollContainer):
		return
	if _autoscroll_running:
		return
	_autoscroll_running = true
	_last_autoscroll_seen_count = -1
	var attempts := 0
	# Wait until child count is stable across a frame (coalesce bursts)
	while true:
		await get_tree().process_frame
		var current := get_child_count()
		if current == _last_autoscroll_seen_count:
			break
		_last_autoscroll_seen_count = current
		attempts += 1
		if attempts > 60:
			print("[ChatLog] Autoscroll: giving up stability wait after %d frames" % attempts)
			break

	var sc := parent_scroll as ScrollContainer
	var vbar := sc.get_v_scroll_bar()
	if vbar:
		vbar.value = vbar.max_value
		print("[ChatLog] Autoscroll bottom after burst (value=%d, max=%d, attempts=%d)." % [vbar.value, vbar.max_value, attempts])
	var last = get_child(get_child_count() - 1) if get_child_count() > 0 else null
	if last and last is Control:
		sc.ensure_control_visible(last)
		print("[ChatLog] ensure_control_visible(last) after burst.")
	_autoscroll_running = false
