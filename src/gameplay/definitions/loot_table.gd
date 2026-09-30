class_name LootTable
extends Resource

@export var entries: Array[LootEntry] = []


## Returns [{ "item": ItemDef, "count": int }, ...]
func roll(rng: RandomNumberGenerator) -> Array[Dictionary]:
	var drops: Array[Dictionary] = []
	for entry: LootEntry in entries:
		if entry == null or entry.item == null:
			continue
		if rng.randf() <= entry.chance:
			var n := rng.randi_range(entry.min_count, maxi(entry.min_count, entry.max_count))
			if n > 0:
				drops.append({"item": entry.item, "count": n})
	return drops
