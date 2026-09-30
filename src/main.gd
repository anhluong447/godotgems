extends Node
## Composition root: wires scene-level systems together and owns game flow rules
## (start, party wipe). Keep it thin; logic belongs in the systems.

@onready var world: MapHost = $World
@onready var party: PartyManager = $PartyManager
@onready var debug_overlay: DebugOverlay = $DebugLayer/DebugOverlay


func _ready() -> void:
	debug_overlay.party = party
	EventBus.party_wiped.connect(_on_party_wiped)
	_register_debug_commands()
	party.build_from_state()
	SceneRouter.change_map(GameState.map_path, GameState.spawn_id, 0.4)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"quick_save"):
		if SaveService.save_game(SaveService.AUTOSAVE_SLOT):
			EventBus.toast_requested.emit("Đã lưu nhanh")
	elif event.is_action_pressed(&"quick_load"):
		if not SaveService.load_game(SaveService.AUTOSAVE_SLOT):
			EventBus.toast_requested.emit("Chưa có bản lưu nhanh")


func _on_party_wiped() -> void:
	EventBus.toast_requested.emit("Cả đội đã ngã... quay về điểm xuất phát.")
	InputGate.acquire(&"wipe")
	await get_tree().create_timer(1.5).timeout
	InputGate.release(&"wipe")
	party.revive_all(1.0)
	SceneRouter.change_map(GameState.map_path, &"")


# --- Debug commands that need the world ---

func _register_debug_commands() -> void:
	DebugService.register("spawn", _cmd_spawn, "Spawn enemies near the leader", "<enemy_id> [count]")
	DebugService.register("give", _cmd_give, "Add items to the inventory", "<item_id> [count]")
	DebugService.register("kill_all", _cmd_kill_all, "Kill every enemy on the map")
	DebugService.register("map", _cmd_map, "Go to a map", "<res://path.tscn> [spawn]")
	DebugService.register("save", _cmd_save, "Save to slot", "<slot>")
	DebugService.register("load", _cmd_load, "Load from slot", "<slot>")
	DebugService.register("enemies", func(_a: PackedStringArray) -> String: return ", ".join(Registry.enemy_ids()), "List enemy ids")
	DebugService.register("items", func(_a: PackedStringArray) -> String: return ", ".join(Registry.item_ids()), "List item ids")


func _cmd_spawn(args: PackedStringArray) -> String:
	if args.is_empty():
		return "usage: spawn <enemy_id> [count]"
	var def := Registry.enemy(StringName(args[0]))
	if def == null:
		return "unknown enemy '%s'. Try: %s" % [args[0], ", ".join(Registry.enemy_ids())]
	if party.leader == null or world.current_map == null:
		return "no map"
	var n := args[1].to_int() if args.size() > 1 else 1
	for i: int in n:
		var e := Enemy.create(def)
		var offset := Vector2.RIGHT.rotated(randf() * TAU) * randf_range(50.0, 90.0)
		e.position = party.leader.position + offset
		world.current_map.entities.add_child(e)
	return "spawned %d %s" % [n, def.id]


func _cmd_give(args: PackedStringArray) -> String:
	if args.is_empty():
		return "usage: give <item_id> [count]"
	var item := Registry.item(StringName(args[0]))
	if item == null:
		return "unknown item '%s'" % args[0]
	var n := args[1].to_int() if args.size() > 1 else 1
	var added := GameState.inventory.add(item.id, n, item.max_stack)
	return "added %d %s" % [added, item.id]


func _cmd_kill_all(_args: PackedStringArray) -> String:
	var n := 0
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		var e := node as Enemy
		if e != null and e.is_alive():
			e.health.kill()
			n += 1
	return "killed %d" % n


func _cmd_map(args: PackedStringArray) -> String:
	if args.is_empty():
		return "current: %s" % GameState.map_path
	SceneRouter.change_map(args[0], StringName(args[1]) if args.size() > 1 else &"")
	return "loading %s" % args[0]


func _cmd_save(args: PackedStringArray) -> String:
	var slot := args[0].to_int() if not args.is_empty() else 1
	return "saved slot %d" % slot if SaveService.save_game(slot) else "save failed"


func _cmd_load(args: PackedStringArray) -> String:
	var slot := args[0].to_int() if not args.is_empty() else 1
	return "loaded slot %d" % slot if SaveService.load_game(slot) else "no save in slot %d" % slot
