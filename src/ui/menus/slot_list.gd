class_name SlotList
extends VBoxContainer
## Save slot picker shared by the title screen (load) and the pause menu (save/load).

signal slot_chosen(slot: int)
signal back_requested

enum Mode { SAVE, LOAD }

var mode: Mode = Mode.LOAD
var _title: Label
var _buttons: VBoxContainer


func _ready() -> void:
	add_theme_constant_override("separation", 3)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 9)
	add_child(_title)
	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 3)
	add_child(_buttons)
	var back := Button.new()
	back.text = "UI_BACK"
	back.pressed.connect(func() -> void: back_requested.emit())
	add_child(back)


func open(p_mode: Mode) -> void:
	mode = p_mode
	_title.text = "UI_CHOOSE_SAVE_SLOT" if mode == Mode.SAVE else "UI_CHOOSE_LOAD_SLOT"
	for child: Node in _buttons.get_children():
		_buttons.remove_child(child)
		child.queue_free()
	var first: Button = null
	for slot: int in SaveService.all_slots():
		# The autosave slot is written by F5 only; players pick manual slots to save.
		if mode == Mode.SAVE and slot == SaveService.AUTOSAVE_SLOT:
			continue
		var meta := SaveService.slot_meta(slot)
		var b := Button.new()
		b.text = slot_text(slot, meta)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 8)
		b.disabled = mode == Mode.LOAD and meta.is_empty()
		b.pressed.connect(func() -> void: slot_chosen.emit(slot))
		_buttons.add_child(b)
		if first == null and not b.disabled:
			first = b
	if first != null:
		first.grab_focus.call_deferred()


func slot_text(slot: int, meta: Dictionary) -> String:
	var slot_name := tr("UI_AUTOSAVE") if slot == SaveService.AUTOSAVE_SLOT else tr("UI_SLOT") % slot
	if meta.is_empty():
		return tr("UI_SLOT_EMPTY") % slot_name
	return tr("UI_SLOT_INFO") % [slot_name, str(meta.get("map_name", "?")), format_playtime(float(meta.get("playtime", 0.0)))]


static func format_playtime(seconds: float) -> String:
	var total := int(seconds)
	return "%d:%02d:%02d" % [floori(total / 3600.0), floori(total / 60.0) % 60, total % 60]
