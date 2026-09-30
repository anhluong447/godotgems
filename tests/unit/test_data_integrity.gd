extends GutTest
## Content rules enforced on every .tres in data/. Adding broken content fails the build.

const MIN_ENEMY_TELEGRAPH := 0.4  # GDD 6.5


func test_registry_loaded_content() -> void:
	assert_gt(Registry.character_ids().size(), 0)
	assert_gt(Registry.enemy_ids().size(), 0)
	assert_gt(Registry.item_ids().size(), 0)
	assert_not_null(Registry.combat_config)


func test_default_party_exists() -> void:
	for id: StringName in GameState.DEFAULT_PARTY:
		assert_not_null(Registry.character(id), "missing character %s" % id)


func test_characters_are_complete() -> void:
	for id: StringName in Registry.character_ids():
		var c := Registry.character(id)
		assert_false(c.combo.is_empty(), "%s has no combo" % id)
		assert_not_null(c.skill_1, "%s skill_1" % id)
		assert_not_null(c.skill_2, "%s skill_2" % id)
		assert_not_null(c.sprite_sheet, "%s sprite" % id)
		assert_gt(c.max_hp, 0.0)
		for a: AbilityDef in c.combo + [c.skill_1, c.skill_2]:
			_check_ability(a, "%s/%s" % [id, a.id])


func test_enemies_are_complete_and_readable() -> void:
	for id: StringName in Registry.enemy_ids():
		var e := Registry.enemy(id)
		assert_gt(e.max_hp, 0.0, "%s hp" % id)
		assert_not_null(e.sprite_sheet, "%s sprite" % id)
		if not e.stationary:
			assert_false(e.abilities.is_empty(), "%s has no abilities" % id)
		for a: AbilityDef in e.abilities:
			_check_ability(a, "%s/%s" % [id, a.id])
			assert_true(a.windup >= MIN_ENEMY_TELEGRAPH,
				"%s/%s windup %.2f < %.2f (every enemy attack needs a readable telegraph)" % [id, a.id, a.windup, MIN_ENEMY_TELEGRAPH])


func test_items_are_complete() -> void:
	for id: StringName in Registry.item_ids():
		var item := Registry.item(id)
		assert_false(item.display_name.is_empty(), "%s name" % id)
		assert_gt(item.max_stack, 0, "%s stack" % id)
		if item.kind == ItemDef.Kind.INSTANT or item.kind == ItemDef.Kind.CONSUMABLE:
			assert_gt(item.heal_amount, 0, "%s heals nothing" % id)


func test_maps_have_required_nodes() -> void:
	for path: String in ["res://maps/test_field.tscn", "res://maps/test_house.tscn"]:
		var map := (load(path) as PackedScene).instantiate() as MapBase
		assert_not_null(map, "%s root must be MapBase" % path)
		if map == null:
			continue
		assert_not_null(map.get_node_or_null("Ground"), "%s Ground" % path)
		assert_not_null(map.get_node_or_null("Entities"), "%s Entities" % path)
		assert_gt(map.get_node("SpawnPoints").get_child_count(), 0, "%s spawn points" % path)
		assert_not_null(map.get_node("SpawnPoints").get_node_or_null(String(map.default_spawn)),
			"%s default_spawn '%s' must exist" % [path, map.default_spawn])
		map.free()


func _check_ability(a: AbilityDef, label: String) -> void:
	assert_not_null(a.behavior, "%s behavior" % label)
	assert_ne(a.id, &"", "%s id" % label)
	assert_true(a.windup >= 0.0 and a.active_time >= 0.0 and a.recovery >= 0.0, "%s timeline" % label)
	if a.behavior is ProjectileBehavior:
		assert_not_null(a.projectile, "%s needs a projectile" % label)
