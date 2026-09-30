class_name DebugOverlay
extends Label
## F3: live numbers for tuning and bug hunting.

var party: PartyManager


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	position = Vector2(640 - 200, 24)
	size = Vector2(194, 200)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_theme_font_size_override("font_size", 7)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 3)


func _unhandled_input(event: InputEvent) -> void:
	if DebugService.enabled and event.is_action_pressed(&"debug_overlay"):
		visible = not visible


func _process(_delta: float) -> void:
	if not visible:
		return
	var lines := PackedStringArray()
	lines.append("FPS %d" % Engine.get_frames_per_second())
	lines.append("nodes %d  orphans %d" % [
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)])
	lines.append("timescale %.2f" % Engine.time_scale)
	lines.append("enemies %d" % get_tree().get_nodes_in_group(&"enemies").size())
	lines.append("input gate: %s" % ("open" if InputGate.is_open() else ", ".join(InputGate.reasons())))
	if party != null and is_instance_valid(party.leader) and party.leader.is_inside_tree():
		var l := party.leader
		lines.append("leader %s  state %s" % [l.def.id, l.state_machine.current_id()])
		lines.append("ability %s  phase %s" % [
			l.abilities.current.id if l.abilities.current else "-",
			AbilityComponent.Phase.keys()[l.abilities.phase]])
		lines.append("hp %.0f/%.0f  energy %.0f  poise %.0f" % [l.health.current(), l.health.pool.maximum, l.energy.current, l.poise.current])
		lines.append("pos %s  combo %d" % [l.global_position.round(), l.combo_index])
	lines.append("god %s  hitboxes %s" % [DebugService.god_mode, DebugService.show_hitboxes])
	text = "\n".join(lines)
