class_name AttackDirector
extends Node
## Lets only a few enemies swing at the party at the same time, so big fights stay
## readable (every attack keeps its telegraph visible instead of 6 overlapping ones).
## Enemies find it through the "attack_director" group; without one, attacks are unlimited.

const GROUP: StringName = &"attack_director"

var tokens: TokenPool = TokenPool.new(2)


func _ready() -> void:
	add_to_group(GROUP)
	tokens = TokenPool.new(Registry.combat_config.max_simultaneous_attackers)
	EventBus.map_loaded.connect(func(_id: StringName, _name: String) -> void: tokens.clear())


func _physics_process(_delta: float) -> void:
	tokens.prune(func(id: int) -> bool: return is_instance_id_valid(id))


func try_acquire(enemy: Node) -> bool:
	return tokens.try_acquire(enemy.get_instance_id())


func release(enemy: Node) -> void:
	tokens.release(enemy.get_instance_id())


## Finds the director in the tree, or null (tests, standalone scenes).
static func find(from: Node) -> AttackDirector:
	if from == null or not from.is_inside_tree():
		return null
	return from.get_tree().get_first_node_in_group(GROUP) as AttackDirector
