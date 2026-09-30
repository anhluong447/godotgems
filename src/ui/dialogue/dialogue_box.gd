class_name DialogueBox
extends Control
## Minimal dialogue UI: typewriter text, speaker name, optional choices.
## Listens to EventBus.dialogue_requested; blocks gameplay input while open.
## Swappable: any other UI that answers dialogue_requested/dialogue_finished works.

const GATE_REASON: StringName = &"dialogue"
const ADVANCE_ACTIONS: Array[StringName] = [&"interact", &"attack", &"ui_accept"]

var _data: DialogueData = null
var _index: int = 0
var _chars: float = 0.0
var _choice_index: int = -1
var _cursor: int = 0
var _opened_frame: int = 0

var _panel: PanelContainer
var _speaker: Label
var _text: RichTextLabel
var _choices: VBoxContainer
var _more: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	visible = false
	EventBus.dialogue_requested.connect(open)


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.position = Vector2(40, 360 - 92)
	_panel.size = Vector2(560, 82)
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	_panel.add_child(box)
	_speaker = Label.new()
	_speaker.add_theme_font_size_override("font_size", 10)
	box.add_child(_speaker)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = false
	_text.scroll_active = false
	_text.custom_minimum_size = Vector2(540, 40)
	box.add_child(_text)
	_choices = VBoxContainer.new()
	box.add_child(_choices)
	_more = Label.new()
	_more.text = "▼"
	_more.position = Vector2(560 + 40 - 18, 360 - 22)
	_more.add_theme_font_size_override("font_size", 8)
	add_child(_more)


func is_open() -> bool:
	return _data != null


func open(data: DialogueData) -> void:
	if data == null or data.lines.is_empty():
		return
	_data = data
	_index = 0
	_choice_index = -1
	_opened_frame = Engine.get_process_frames()
	InputGate.acquire(GATE_REASON)
	visible = true
	_show_line()


func _show_line() -> void:
	var line := _data.lines[_index]
	_speaker.text = line.speaker
	_speaker.add_theme_color_override("font_color", line.speaker_color)
	_text.text = line.text
	_text.visible_characters = 0
	_chars = 0.0
	for child: Node in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()
	_cursor = 0
	_more.visible = false


func _process(delta: float) -> void:
	if _data == null:
		return
	var line := _data.lines[_index]
	var total := _text.get_total_character_count()
	if _text.visible_characters < total:
		var before := int(_chars)
		_chars += delta * float(SettingsService.get_value(&"text_speed"))
		_text.visible_characters = int(_chars)
		if int(_chars) != before and int(_chars) % 3 == 0:
			AudioService.play_ui(&"text_blip")
	elif not line.choices.is_empty() and _choices.get_child_count() == 0:
		_show_choices(line.choices)
	else:
		_more.visible = line.choices.is_empty()
		_more.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 150.0)
	# Ignore the key press that opened the dialogue (or picked the last choice).
	if Engine.get_process_frames() == _opened_frame:
		return
	if _choices.get_child_count() > 0:
		_handle_choice_input()
	elif line.choices.is_empty() and _advance_pressed():
		if _text.visible_characters < total:
			_text.visible_characters = total
			_chars = total
		else:
			_next()


## Choices are navigated here (not via GUI focus) so keyboard, WASD, gamepad and
## simulated input all behave the same. Mouse clicks still work through `pressed`.
func _show_choices(options: PackedStringArray) -> void:
	for i: int in options.size():
		var b := Button.new()
		b.text = options[i]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_on_choice.bind(i))
		b.mouse_entered.connect(_set_cursor.bind(i))
		_choices.add_child(b)
	_set_cursor(0)


func _handle_choice_input() -> void:
	if _just_pressed([&"move_up", &"ui_up"]):
		_set_cursor(_cursor - 1)
	elif _just_pressed([&"move_down", &"ui_down"]):
		_set_cursor(_cursor + 1)
	elif _advance_pressed():
		_on_choice(_cursor)


func _set_cursor(index: int) -> void:
	var count := _choices.get_child_count()
	if count == 0:
		return
	var next := wrapi(index, 0, count)
	if next != _cursor:
		AudioService.play_ui(&"ui_move")
	_cursor = next
	for i: int in count:
		var b := _choices.get_child(i) as Button
		if i == _cursor:
			b.add_theme_stylebox_override(&"normal", b.get_theme_stylebox(&"hover"))
		else:
			b.remove_theme_stylebox_override(&"normal")
		b.text = ("▶ " if i == _cursor else "   ") + b.text.trim_prefix("▶ ").trim_prefix("   ")


func _on_choice(index: int) -> void:
	AudioService.play_ui(&"ui_confirm")
	_choice_index = index
	_opened_frame = Engine.get_process_frames()
	_next()


func _next() -> void:
	_index += 1
	if _index >= _data.lines.size():
		_close()
	else:
		_show_line()


func _close() -> void:
	var data := _data
	_data = null
	visible = false
	InputGate.release(GATE_REASON)
	EventBus.dialogue_finished.emit(data, _choice_index)


func _advance_pressed() -> bool:
	return _just_pressed(ADVANCE_ACTIONS)


static func _just_pressed(actions: Array[StringName]) -> bool:
	for action: StringName in actions:
		if Input.is_action_just_pressed(action):
			return true
	return false
