class_name DamageCalculator
extends RefCounted
## Pure damage formula:
##   dmg = raw * def_scale / (def_scale + def) * variance * crit
## Tuning numbers come from CombatConfig (data/config/combat_config.tres).


static func compute(raw: float, defense: float, config: CombatConfig, rng: RandomNumberGenerator) -> Dictionary:
	var reduced := raw * config.def_scale / (config.def_scale + maxf(defense, 0.0))
	var variance := 1.0 + rng.randf_range(-config.variance, config.variance)
	var is_crit := rng.randf() < config.crit_chance
	var amount := reduced * variance * (config.crit_multiplier if is_crit else 1.0)
	return {
		"amount": maxi(roundi(amount), config.min_damage),
		"crit": is_crit,
	}


static func resolve(info: DamageInfo, defense: float, config: CombatConfig, rng: RandomNumberGenerator) -> void:
	var result := compute(info.raw_damage(), defense, config, rng)
	info.final_amount = result["amount"]
	info.is_crit = result["crit"]
