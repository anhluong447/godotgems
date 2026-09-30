class_name Hud
extends Control
## In-game HUD: party frames, leader skills, wallet, toasts, interaction prompt, map banner.
## Read-only view: it polls/listens and never changes gameplay state.

const FRAME_WIDTH := 92.0
const TOAST_TIME := 2.2
const WALLET_ITEM: StringName = &"coin"

var _members: Array[PartyMember] = []
var _leader: PartyMember = null
var _frames: Array[Dictionary] = []
var _frames_box: VBoxContainer
var _skills_box: HBoxContainer
var _skill_slots: Array[Dictionary] = []
var _wallet: Label
var _toasts: VBoxContainer
var _prompt: Label
var _prompt_target: InteractableComponent = null
var _banner: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	EventBus.party_roster_changed.connect(_on_roster_changed)
	EventBus.party_leader_changed.connect(_on_leader_changed)
	EventBus.toast_requested.connect(show_toast)
	EventBus.interaction_focus_changed.connect(func(t: Node2D) -> void: _prompt_target = t as InteractableComponent)
	EventBus.map_loaded.connect(_on_map_loaded)
	GameState.inventory.changed.connect(func(_id: StringName, _c: int) -> void: _refresh_wallet())
	GameState.inventory.reset.connect(_refresh_wallet)
	_refresh_wallet()


func _process(_delta: float) -> void:
	_update_frames()
	_update_skills()
	_update_prompt()


# --- Build ---

func _build() -> void:
	_frames_box = VBoxContainer.new()
	_frames_box.position = Vector2(6, 6)
	_frames_box.add_theme_constant_override("separation", 3)
	add_child(_frames_box)

	_skills_box = HBoxContainer.new()
	_skills_box.position = Vector2(640 - 104, 360 - 36)
	_skills_box.add_theme_constant_override("separation", 4)
	add_child(_skills_box)
	for action: StringName in [&"skill_1", &"skill_2", &"dodge"]:
		_skill_slots.append(_make_skill_slot(InputHints.key_for(action)))

	_wallet = Label.new()
	_wallet.position = Vector2(640 - 130, 6)
	_wallet.size = Vector2(124, 14)
	_wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_wallet)

	_toasts = VBoxContainer.new()
	_toasts.position = Vector2(8, 360 - 90)
	_toasts.size = Vector2(220, 80)
	_toasts.alignment = BoxContainer.ALIGNMENT_END
	add_child(_toasts)

	_prompt = Label.new()
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.size = Vector2(120, 14)
	_prompt.add_theme_font_size_override("font_size", 8)
	_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_prompt.add_theme_constant_override("outline_size", 3)
	_prompt.visible = false
	add_child(_prompt)

	_banner = Label.new()
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.position = Vector2(0, 40)
	_banner.size = Vector2(640, 20)
	_banner.add_theme_font_size_override("font_size", 14)
	_banner.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_banner.add_theme_constant_override("outline_size", 4)
	_banner.modulate.a = 0.0
	add_child(_banner)


func _make_skill_slot(key: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(28, 28)
	var root := Control.new()
	root.custom_minimum_size = Vector2(20, 20)
	panel.add_child(root)
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 7)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(label)
	var cover := ColorRect.new()
	cover.color = Color(0, 0, 0, 0.6)
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(cover)
	var key_label := Label.new()
	key_label.text = key
	key_label.add_theme_font_size_override("font_size", 7)
	key_label.add_theme_color_override("font_color", Color(1, 0.85, 0.5))
	key_label.position = Vector2(-4, -6)
	root.add_child(key_label)
	_skills_box.add_child(panel)
	return {"panel": panel, "label": label, "cover": cover}


func _make_frame(m: PartyMember, index: int) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(FRAME_WIDTH, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	panel.add_child(box)
	var title := Label.new()
	title.text = "%d  %s" % [index + 1, m.def.display_name]
	title.add_theme_font_size_override("font_size", 8)
	box.add_child(title)
	var hp := _make_bar(Color(0.86, 0.3, 0.3), 5)
	box.add_child(hp)
	var en := _make_bar(Color(0.35, 0.75, 0.95), 3)
	box.add_child(en)
	_frames_box.add_child(panel)
	return {"member": m, "panel": panel, "title": title, "hp": hp, "energy": en, "index": index}


func _make_bar(color: Color, height: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(FRAME_WIDTH - 12, height)
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)
	return bar


# --- Update ---

func _on_roster_changed(members: Array[Node2D]) -> void:
	for f: Dictionary in _frames:
		(f["panel"] as Control).queue_free()
	_frames.clear()
	_members.clear()
	for i: int in members.size():
		var m := members[i] as PartyMember
		_members.append(m)
		_frames.append(_make_frame(m, i))


func _on_leader_changed(leader: Node2D) -> void:
	_leader = leader as PartyMember


func _update_frames() -> void:
	for f: Dictionary in _frames:
		var m: PartyMember = f["member"]
		if not is_instance_valid(m) or not m.is_inside_tree():
			continue
		var hp: ProgressBar = f["hp"]
		hp.max_value = m.health.pool.maximum
		hp.value = m.health.pool.current
		var en: ProgressBar = f["energy"]
		en.max_value = maxf(m.energy.maximum, 1.0)
		en.value = m.energy.current
		var title: Label = f["title"]
		var text := "%d  %s  %s" % [int(f["index"]) + 1, m.def.display_name, tr("HUD_LEVEL") % m.progression.level]
		if m.is_downed():
			var downed := m.state_machine.current as Node
			var left: float = downed.call("time_left") if downed.has_method("time_left") else 0.0
			text += "  " + tr("HUD_DOWNED") % ceili(left)
		title.text = text
		var panel: Control = f["panel"]
		panel.modulate = Color.WHITE if m == _leader else Color(1, 1, 1, 0.6)
		if m.is_downed():
			panel.modulate = Color(0.6, 0.5, 0.5, 0.7)


func _update_skills() -> void:
	if not is_instance_valid(_leader) or not _leader.is_inside_tree():
		return
	var skills: Array[AbilityDef] = [_leader.def.skill_1, _leader.def.skill_2]
	for i: int in 2:
		var slot := _skill_slots[i]
		var s := skills[i]
		var label: Label = slot["label"]
		var cover: ColorRect = slot["cover"]
		if s == null:
			label.text = "-"
			cover.anchor_top = 0.0
			continue
		label.text = s.display_name.left(6)
		var ratio := _leader.abilities.cooldown_ratio(s)
		cover.anchor_top = 1.0 - ratio
		cover.offset_top = 0.0
		(slot["panel"] as Control).modulate = Color.WHITE if _leader.energy.can_afford(s.energy_cost) else Color(0.6, 0.6, 0.8)
	var dodge := _skill_slots[2]
	(dodge["label"] as Label).text = tr("HUD_DODGE")
	var dodge_cover: ColorRect = dodge["cover"]
	dodge_cover.anchor_top = 1.0 - _leader.dodge_cooldown.ratio()
	dodge_cover.offset_top = 0.0


func _update_prompt() -> void:
	if not is_instance_valid(_prompt_target) or not InputGate.is_open():
		_prompt.visible = false
		return
	_prompt.visible = true
	_prompt.text = tr("HUD_PROMPT") % [InputHints.key_for(&"interact"), tr(_prompt_target.prompt)]
	# World -> screen -> HUD local; both sides include the same stretch transform, so it cancels.
	var screen := _prompt_target.get_global_transform_with_canvas() * _prompt_target.prompt_offset
	var local := get_global_transform_with_canvas().affine_inverse() * screen
	_prompt.position = local - Vector2(_prompt.size.x * 0.5, 0)


func _refresh_wallet() -> void:
	var parts := PackedStringArray()
	for id: StringName in GameState.inventory.item_ids():
		var item := Registry.item(id)
		var n := GameState.inventory.count(id)
		parts.append("%s ×%d" % [item.display_name if item != null else String(id), n])
	_wallet.text = "   ".join(parts)


func show_toast(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 3)
	_toasts.add_child(label)
	if _toasts.get_child_count() > 5:
		_toasts.get_child(0).queue_free()
	var tween := label.create_tween()
	tween.tween_interval(TOAST_TIME)
	tween.tween_property(label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(label.queue_free)


func _on_map_loaded(_map_id: StringName, map_name: String) -> void:
	if map_name.is_empty():
		return
	_banner.text = map_name
	var tween := create_tween()
	tween.tween_property(_banner, "modulate:a", 1.0, 0.3)
	tween.tween_interval(1.4)
	tween.tween_property(_banner, "modulate:a", 0.0, 0.6)
