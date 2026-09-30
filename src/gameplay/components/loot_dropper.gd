class_name LootDropper
extends Node
## Rolls a LootTable and scatters pickups into the world.

const PICKUP_SCENE := preload("res://src/gameplay/entities/props/pickup.tscn")

@export var table: LootTable

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


## `container` is where pickups are added (normally the map's Entities node).
func drop(at: Vector2, container: Node) -> void:
	if table == null or container == null:
		return
	for drop_data: Dictionary in table.roll(_rng):
		var item: ItemDef = drop_data["item"]
		var count: int = drop_data["count"]
		# Stackable currency drops as one pickup; others as individual pickups.
		var pieces := 1 if item.kind == ItemDef.Kind.MATERIAL else count
		var per_piece := count if pieces == 1 else 1
		for i: int in pieces:
			var pickup := PICKUP_SCENE.instantiate() as Pickup
			pickup.item = item
			pickup.count = per_piece
			container.add_child(pickup)
			pickup.global_position = at
			pickup.pop(Vector2.RIGHT.rotated(_rng.randf() * TAU) * _rng.randf_range(40.0, 90.0))
