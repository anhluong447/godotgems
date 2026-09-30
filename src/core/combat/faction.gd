class_name Faction
extends RefCounted
## Who can hurt whom, expressed as physics layers. Layer numbers match project settings.

enum Id { PARTY, ENEMY, NEUTRAL }

const LAYER_WORLD := 1
const LAYER_PARTY := 2
const LAYER_ENEMY := 3
const LAYER_PARTY_HURTBOX := 4
const LAYER_ENEMY_HURTBOX := 5
const LAYER_INTERACTABLE := 6
const LAYER_PICKUP := 7
const LAYER_NEUTRAL_HURTBOX := 8


static func bit(layer: int) -> int:
	return 1 << (layer - 1)


static func hurtbox_layer(faction: Id) -> int:
	match faction:
		Id.PARTY:
			return bit(LAYER_PARTY_HURTBOX)
		Id.ENEMY:
			return bit(LAYER_ENEMY_HURTBOX)
		_:
			return bit(LAYER_NEUTRAL_HURTBOX)


## Mask a hitbox owned by `faction` should scan.
static func hitbox_mask(faction: Id) -> int:
	match faction:
		Id.PARTY:
			return bit(LAYER_ENEMY_HURTBOX) | bit(LAYER_NEUTRAL_HURTBOX)
		Id.ENEMY:
			return bit(LAYER_PARTY_HURTBOX)
		_:
			return 0


static func body_layer(faction: Id) -> int:
	match faction:
		Id.PARTY:
			return bit(LAYER_PARTY)
		Id.ENEMY:
			return bit(LAYER_ENEMY)
		_:
			return bit(LAYER_WORLD)


static func is_hostile(a: Id, b: Id) -> bool:
	if a == b:
		return false
	# Neutral things (pots, crates) can be broken by the party only.
	if b == Id.NEUTRAL:
		return a == Id.PARTY
	if a == Id.NEUTRAL:
		return false
	return true
