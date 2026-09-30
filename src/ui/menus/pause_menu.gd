class_name PauseMenu
extends Control
## Pause menu: resume, inventory, save/load (slot picker), settings, back to title.
## Runs while the tree is paused. Pages are shared widgets (InventoryPanel, SlotList, SettingsPanel).

var _panel: PanelContainer
var _title: Label
var _root_page: VBoxContainer
var _inventory: InventoryPanel
var _slots: SlotList
var _settings: SettingsPanel
var _status: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"pause"):
		return
	if InputGate.reasons().has(&"console") or InputGate.reasons().has(&"transition"):
		return
	if visible and not _root_page.visible:
		_show_page(_root_page)
	else:
		toggle()
	get_viewport().set_input_as_handled()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	visible = true
	get_tree().paused = true
	_status.text = ""
	_show_page(_root_page)
	AudioService.play_ui(&"ui_confirm")


func close() -> void:
	visible = false
	get_tree().paused = false
	AudioService.play_ui(&"ui_back")


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(220, 0)
	add_child(_panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 4)
	_panel.add_child(outer)
	_title = Label.new()
	_title.text = "UI_PAUSE_TITLE"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 14)
	outer.add_child(_title)

	_root_page = VBoxContainer.new()
	_root_page.add_theme_constant_override("separation", 3)
	outer.add_child(_root_page)
	_add_button(_root_page, "UI_RESUME", close)
	_add_button(_root_page, "UI_INVENTORY", func() -> void: _show_page(_inventory))
	_add_button(_root_page, "UI_SAVE", func() -> void: _show_page(_slots, SlotList.Mode.SAVE))
	_add_button(_root_page, "UI_LOAD", func() -> void: _show_page(_slots, SlotList.Mode.LOAD))
	_add_button(_root_page, "UI_SETTINGS", func() -> void: _show_page(_settings))
	_add_button(_root_page, "UI_TO_TITLE", _on_to_title)
	_add_button(_root_page, "UI_QUIT", func() -> void: get_tree().quit())

	_inventory = InventoryPanel.new()
	_inventory.back_requested.connect(func() -> void: _show_page(_root_page))
	outer.add_child(_inventory)
	_slots = SlotList.new()
	_slots.back_requested.connect(func() -> void: _show_page(_root_page))
	_slots.slot_chosen.connect(_on_slot_chosen)
	outer.add_child(_slots)
	_settings = SettingsPanel.new()
	_settings.back_requested.connect(func() -> void: _show_page(_root_page))
	outer.add_child(_settings)

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 8)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(_status)


func _add_button(parent: Control, key: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = key
	b.pressed.connect(callback)
	b.focus_entered.connect(func() -> void: AudioService.play_ui(&"ui_move"))
	parent.add_child(b)
	return b


func _show_page(page: Control, slot_mode: SlotList.Mode = SlotList.Mode.LOAD) -> void:
	for p: Control in [_root_page, _inventory, _slots, _settings]:
		p.visible = p == page
	if page == _root_page:
		(_root_page.get_child(0) as Button).grab_focus.call_deferred()
	elif page == _inventory:
		_inventory.open()
	elif page == _slots:
		_slots.open(slot_mode)
	elif page == _settings:
		_settings.focus_first()
	_center_panel.call_deferred()


func _center_panel() -> void:
	_panel.reset_size()
	_panel.position = ((get_viewport_rect().size - _panel.size) * 0.5).floor()


func _on_slot_chosen(slot: int) -> void:
	if _slots.mode == SlotList.Mode.SAVE:
		var ok := SaveService.save_game(slot)
		_status.text = tr("UI_SAVED_SLOT") % (tr("UI_SLOT") % slot) if ok else tr("UI_SAVE_FAILED")
		_slots.open(SlotList.Mode.SAVE)
	else:
		close()
		if not SaveService.load_game(slot):
			EventBus.toast_requested.emit(tr("UI_LOAD_FAILED"))


func _on_to_title() -> void:
	visible = false
	SceneRouter.change_scene(SceneRouter.TITLE_SCENE)
