class_name InventoryPanel
extends VBoxContainer
## Read-only view of the inventory. "Use" sends EventBus.item_use_requested; gameplay decides.

signal back_requested

var _list: VBoxContainer
var _description: Label
var _use_button: Button
var _empty: Label
var _selected: StringName = &""


func _ready() -> void:
	add_theme_constant_override("separation", 3)
	_empty = Label.new()
	_empty.text = "UI_EMPTY_INVENTORY"
	_empty.add_theme_font_size_override("font_size", 8)
	add_child(_empty)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 2)
	add_child(_list)
	_description = Label.new()
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.custom_minimum_size = Vector2(190, 24)
	_description.add_theme_font_size_override("font_size", 8)
	_description.add_theme_color_override("font_color", Color(0.85, 0.85, 0.8))
	add_child(_description)
	_use_button = Button.new()
	_use_button.text = "UI_USE"
	_use_button.pressed.connect(_on_use)
	add_child(_use_button)
	var back := Button.new()
	back.text = "UI_BACK"
	back.pressed.connect(func() -> void: back_requested.emit())
	add_child(back)
	GameState.inventory.changed.connect(func(_id: StringName, _c: int) -> void: _refresh_if_visible())
	GameState.inventory.reset.connect(_refresh_if_visible)


func open() -> void:
	refresh()
	if _list.get_child_count() > 0:
		(_list.get_child(0) as Button).grab_focus.call_deferred()
	else:
		(get_child(get_child_count() - 1) as Button).grab_focus.call_deferred()


func refresh() -> void:
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var ids := GameState.inventory.item_ids()
	_empty.visible = ids.is_empty()
	for id: StringName in ids:
		var item := Registry.item(id)
		var b := Button.new()
		b.text = "%s ×%d" % [item.display_name if item != null else String(id), GameState.inventory.count(id)]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 8)
		if item != null and item.icon != null:
			b.icon = item.icon
		b.focus_entered.connect(_select.bind(id))
		b.pressed.connect(_select.bind(id))
		_list.add_child(b)
	if not GameState.inventory.has(_selected):
		_selected = ids[0] if not ids.is_empty() else &""
	_select(_selected)


func _select(id: StringName) -> void:
	_selected = id
	var item := Registry.item(id) if id != &"" else null
	_description.text = item.description if item != null else ""
	_use_button.disabled = item == null or item.kind != ItemDef.Kind.CONSUMABLE


func _on_use() -> void:
	if _selected != &"":
		EventBus.item_use_requested.emit(_selected)


func _refresh_if_visible() -> void:
	if is_visible_in_tree():
		refresh()
