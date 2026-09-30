class_name DialogueData
extends Resource
## A sequence of lines. Future story tooling (Script Lite / Dialogue Manager) can
## produce DialogueData, or replace the dialogue UI, without touching NPCs.

@export var id: StringName
@export var lines: Array[DialogueLine] = []


static func from_text(speaker: String, texts: PackedStringArray) -> DialogueData:
	var data := DialogueData.new()
	for t: String in texts:
		var line := DialogueLine.new()
		line.speaker = speaker
		line.text = t
		data.lines.append(line)
	return data
