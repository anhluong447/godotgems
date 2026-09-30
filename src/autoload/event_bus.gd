extends Node
## Global signal hub for systems that should not know about each other.
## Rule: only cross-system notifications live here. Parent/child communication
## uses direct calls (down) and local signals (up).
##
## Signals are emitted by their owning system; any system may listen.

# --- Combat ---
## A hurtbox accepted a hit. `target` is the actor/prop that was hit.
@warning_ignore("unused_signal")
signal damage_applied(target: Node2D, info: DamageInfo)
@warning_ignore("unused_signal")
signal enemy_killed(enemy_id: StringName, xp: int, at: Vector2)
@warning_ignore("unused_signal")
signal camera_shake_requested(trauma: float)

# --- Party ---
## Members were (re)built, e.g. new game or load. HUD rebinds on this.
@warning_ignore("unused_signal")
signal party_roster_changed(members: Array[Node2D])
@warning_ignore("unused_signal")
signal party_leader_changed(leader: Node2D)
@warning_ignore("unused_signal")
signal party_member_downed(member: Node2D)
@warning_ignore("unused_signal")
signal party_member_revived(member: Node2D)
@warning_ignore("unused_signal")
signal party_wiped
@warning_ignore("unused_signal")
signal member_leveled_up(character_id: StringName, level: int)

# --- Items & interaction ---
@warning_ignore("unused_signal")
signal item_collected(item_id: StringName, count: int)
## `target` is the focused InteractableComponent, or null when nothing is in reach.
@warning_ignore("unused_signal")
signal interaction_focus_changed(target: Node2D)

# --- Dialogue ---
@warning_ignore("unused_signal")
signal dialogue_requested(data: DialogueData)
@warning_ignore("unused_signal")
signal dialogue_finished(data: DialogueData, choice_index: int)

# --- World / flow ---
@warning_ignore("unused_signal")
signal map_loaded(map_id: StringName, display_name: String)
@warning_ignore("unused_signal")
signal palette_requested(preset: StringName)
@warning_ignore("unused_signal")
signal toast_requested(text: String)
## Fired right before a save is written so runtime systems can sync into GameState.
@warning_ignore("unused_signal")
signal before_save
## Fired after GameState was replaced by loaded data.
@warning_ignore("unused_signal")
signal after_load
