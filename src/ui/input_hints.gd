class_name InputHints
extends RefCounted
## Human-readable key names for actions, read from the Input Map (so hints follow rebinding).


static func key_for(action: StringName) -> String:
	for ev: InputEvent in InputMap.action_get_events(action):
		var key := ev as InputEventKey
		if key == null:
			continue
		var code := key.keycode
		if code == KEY_NONE and key.physical_keycode != KEY_NONE:
			# Headless servers cannot map layouts; physical codes match a US layout.
			code = key.physical_keycode if DisplayServer.get_name() == "headless" \
				else DisplayServer.keyboard_get_keycode_from_physical(key.physical_keycode)
		if code == KEY_SPACE:
			return "␣"
		return OS.get_keycode_string(code)
	return "?"
