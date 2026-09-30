class_name StatsComponent
extends Node
## Node wrapper around a StatBlock so scenes can share stats between components.

signal changed

var block: StatBlock = StatBlock.new()


func setup(base: Dictionary) -> void:
	if block.changed.is_connected(_on_block_changed):
		block.changed.disconnect(_on_block_changed)
	block = StatBlock.new(base)
	block.changed.connect(_on_block_changed)
	changed.emit()


func get_stat(stat: StringName) -> float:
	return block.get_stat(stat)


func _on_block_changed() -> void:
	changed.emit()
