extends GutTest


func _config(variance: float = 0.0, crit: float = 0.0) -> CombatConfig:
	var c := CombatConfig.new()
	c.def_scale = 20.0
	c.variance = variance
	c.crit_chance = crit
	c.crit_multiplier = 2.0
	c.min_damage = 1
	return c


func _rng() -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = 42
	return r


func test_damage_formula_without_variance() -> void:
	# 12 atk * 1.0 power vs 4 def: 12 * 20 / 24 = 10
	var result := DamageCalculator.compute(12.0, 4.0, _config(), _rng())
	assert_eq(result["amount"], 10)
	assert_false(result["crit"])


func test_damage_zero_defense_is_raw() -> void:
	assert_eq(DamageCalculator.compute(15.0, 0.0, _config(), _rng())["amount"], 15)


func test_damage_has_minimum() -> void:
	assert_eq(DamageCalculator.compute(0.1, 999.0, _config(), _rng())["amount"], 1)


func test_guaranteed_crit_doubles() -> void:
	var result := DamageCalculator.compute(10.0, 0.0, _config(0.0, 1.0), _rng())
	assert_true(result["crit"])
	assert_eq(result["amount"], 20)


func test_variance_stays_in_range() -> void:
	var cfg := _config(0.1)
	var rng := _rng()
	for i: int in 200:
		var amount: int = DamageCalculator.compute(100.0, 0.0, cfg, rng)["amount"]
		assert_between(amount, 90, 110)


func test_resolve_fills_damage_info() -> void:
	var info := DamageInfo.new()
	info.attacker_atk = 10.0
	info.power = 2.0
	DamageCalculator.resolve(info, 0.0, _config(), _rng())
	assert_eq(info.final_amount, 20)


func test_damage_info_copy_is_independent() -> void:
	var info := DamageInfo.new()
	info.tags = [&"fire"]
	var c := info.copy()
	c.tags.append(&"ice")
	assert_eq(info.tags.size(), 1)


func test_faction_hostility() -> void:
	assert_true(Faction.is_hostile(Faction.Id.PARTY, Faction.Id.ENEMY))
	assert_true(Faction.is_hostile(Faction.Id.ENEMY, Faction.Id.PARTY))
	assert_false(Faction.is_hostile(Faction.Id.PARTY, Faction.Id.PARTY))
	assert_true(Faction.is_hostile(Faction.Id.PARTY, Faction.Id.NEUTRAL), "party breaks pots")
	assert_false(Faction.is_hostile(Faction.Id.ENEMY, Faction.Id.NEUTRAL), "enemies do not")


func test_faction_masks_match_hurtbox_layers() -> void:
	assert_true(Faction.hitbox_mask(Faction.Id.PARTY) & Faction.hurtbox_layer(Faction.Id.ENEMY) != 0)
	assert_true(Faction.hitbox_mask(Faction.Id.ENEMY) & Faction.hurtbox_layer(Faction.Id.PARTY) != 0)
	assert_eq(Faction.hitbox_mask(Faction.Id.ENEMY) & Faction.hurtbox_layer(Faction.Id.ENEMY), 0)
