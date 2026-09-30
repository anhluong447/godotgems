class_name SaveCodec
extends RefCounted
## Pure encode/decode of save data. Decoding always runs migrations.


static func encode(data: Dictionary) -> String:
	return JSON.stringify(data, "\t")


## Returns the migrated dictionary, or {} if the text is not a valid save.
static func decode(text: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return {}
	var data: Dictionary = json.data
	if not data.has("save_version"):
		return {}
	return SaveMigrator.migrate(data)
