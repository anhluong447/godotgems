class_name DebugConsole
extends PanelContainer
## ` or F1: command console backed by DebugService.

const GATE_REASON: StringName = &"console"
const MAX_LINES := 200

var _log: RichTextLabel
var _input: LineEdit
var _history: PackedStringArray = PackedStringArray()
var _history_index: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	position = Vector2(4, 4)
	size = Vector2(632, 150)
	var box := VBoxContainer.new()
	add_child(box)
	_log = RichTextLabel.new()
	_log.custom_minimum_size = Vector2(620, 120)
	_log.scroll_following = true
	_log.add_theme_font_size_override("normal_font_size", 8)
	box.add_child(_log)
	_input = LineEdit.new()
	_input.placeholder_text = "help"
	_input.add_theme_font_size_override("font_size", 8)
	_input.text_submitted.connect(_on_submit)
	_input.gui_input.connect(_on_input_gui)
	box.add_child(_input)
	DebugService.output.connect(_print)
	_print("Debug console. Type 'help'.")


func _unhandled_input(event: InputEvent) -> void:
	if DebugService.enabled and event.is_action_pressed(&"debug_console"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	visible = not visible
	if visible:
		InputGate.acquire(GATE_REASON)
		_input.clear()
		_input.grab_focus.call_deferred()
	else:
		InputGate.release(GATE_REASON)
		_input.release_focus()


func _on_submit(line: String) -> void:
	_input.clear()
	if line.strip_edges().is_empty():
		return
	_history.append(line)
	_history_index = _history.size()
	_print("> " + line)
	DebugService.execute(line)


func _on_input_gui(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return
	if event.is_action(&"debug_console"):
		toggle()
		_input.accept_event()
	elif key.keycode == KEY_UP and not _history.is_empty():
		_history_index = maxi(_history_index - 1, 0)
		_input.text = _history[_history_index]
		_input.caret_column = _input.text.length()
		_input.accept_event()
	elif key.keycode == KEY_DOWN and not _history.is_empty():
		_history_index = mini(_history_index + 1, _history.size())
		_input.text = _history[_history_index] if _history_index < _history.size() else ""
		_input.accept_event()


func _print(text: String) -> void:
	_log.add_text(text + "\n")
	if _log.get_line_count() > MAX_LINES:
		_log.remove_paragraph(0)
