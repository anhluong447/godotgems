extends SceneTree
## Builds the TileSet and the backbone test maps from code (reproducible layout).
## Run after generate_placeholders.gd and an --import:
##   godot --headless --path . -s res://tools/build_maps.gd
## The generated .tscn files are normal scenes: edit them freely in the editor afterwards
## (re-running this tool overwrites them).

const T := 32
const TILESET_PATH := "res://assets/tilesets/xuan_field_tileset.tres"
const ATLAS_PATH := "res://assets/tilesets/xuan_field.png"
const FIELD_PATH := "res://maps/test_field.tscn"
const HOUSE_PATH := "res://maps/test_house.tscn"

# Atlas coordinates
const G1 := Vector2i(0, 0)
const G2 := Vector2i(1, 0)
const GF := Vector2i(2, 0)
const P1 := Vector2i(3, 0)
const P2 := Vector2i(4, 0)
const WOOD := Vector2i(5, 0)
const WATER := Vector2i(6, 0)
const BRIDGE := Vector2i(7, 0)
const WALL := Vector2i(0, 1)
const ROCK := Vector2i(1, 1)
const FENCE := Vector2i(2, 1)
const BUSH := Vector2i(3, 1)
const IWALL := Vector2i(4, 1)
const TALL := Vector2i(5, 1)
const FLOWERS := Vector2i(6, 1)
const ROOF := Vector2i(7, 1)
const SOLID: Array[Vector2i] = [WATER, WALL, ROCK, FENCE, BUSH, IWALL, ROOF]

const MAP_SCRIPT := "res://src/gameplay/world/map_base.gd"
const S_TREE := "res://src/gameplay/entities/props/tree.tscn"
const S_CHEST := "res://src/gameplay/entities/props/chest.tscn"
const S_SIGN := "res://src/gameplay/entities/props/sign_post.tscn"
const S_DOOR := "res://src/gameplay/entities/props/door.tscn"
const S_POT := "res://src/gameplay/entities/props/breakable_pot.tscn"
const S_NPC := "res://src/gameplay/entities/props/npc.tscn"
const S_ENEMY := "res://src/gameplay/entities/enemies/enemy.tscn"
const S_SPAWNER := "res://src/gameplay/world/spawner.gd"

var rng := RandomNumberGenerator.new()


func _initialize() -> void:
	rng.seed = 2024
	var ts := _build_tileset()
	_build_field(ts)
	_build_house(ts)
	print("Maps built.")
	quit()


# --- TileSet ---

func _build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	var src := TileSetAtlasSource.new()
	src.texture = load(ATLAS_PATH)
	src.texture_region_size = Vector2i(T, T)
	ts.add_source(src, 0)
	var half := T / 2.0
	var square := PackedVector2Array([Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)])
	for y: int in 2:
		for x: int in 8:
			var c := Vector2i(x, y)
			src.create_tile(c)
			if SOLID.has(c):
				var data := src.get_tile_data(c, 0)
				data.add_collision_polygon(0)
				data.set_collision_polygon_points(0, 0, square)
	var err := ResourceSaver.save(ts, TILESET_PATH)
	if err != OK:
		push_error("Could not save tileset: %s" % error_string(err))
	return load(TILESET_PATH)


# --- Map scaffolding ---

func _new_map(node_name: String, map_id: StringName, display_name: String, palette: StringName, ts: TileSet) -> Dictionary:
	var root := Node2D.new()
	root.name = node_name
	root.set_script(load(MAP_SCRIPT))
	root.set("map_id", map_id)
	root.set("display_name", display_name)
	root.set("palette", palette)
	var ground := TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = ts
	root.add_child(ground)
	ground.owner = root
	var decor := TileMapLayer.new()
	decor.name = "Decor"
	decor.tile_set = ts
	decor.collision_enabled = false
	root.add_child(decor)
	decor.owner = root
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	root.add_child(entities)
	entities.owner = root
	var spawns := Node2D.new()
	spawns.name = "SpawnPoints"
	root.add_child(spawns)
	spawns.owner = root
	return {"root": root, "ground": ground, "decor": decor, "entities": entities, "spawns": spawns}


func _add(map: Dictionary, scene_path: String, pos: Vector2, node_name: String, props: Dictionary = {}) -> Node:
	var inst := (load(scene_path) as PackedScene).instantiate()
	inst.name = node_name
	inst.position = pos
	for key: String in props:
		inst.set(key, props[key])
	(map["entities"] as Node).add_child(inst)
	inst.owner = map["root"]
	return inst


func _add_spawner(map: Dictionary, pos: Vector2, node_name: String, enemy_id: String, count: int, radius: float) -> void:
	var s := Node2D.new()
	s.set_script(load(S_SPAWNER))
	s.name = node_name
	s.position = pos
	s.set("enemy", load("res://data/enemies/%s.tres" % enemy_id))
	s.set("count", count)
	s.set("radius", radius)
	(map["entities"] as Node).add_child(s)
	s.owner = map["root"]


func _marker(map: Dictionary, marker_name: String, pos: Vector2) -> void:
	var m := Marker2D.new()
	m.name = marker_name
	m.position = pos
	(map["spawns"] as Node).add_child(m)
	m.owner = map["root"]


func _save(map: Dictionary, path: String) -> void:
	var packed := PackedScene.new()
	var err := packed.pack(map["root"])
	if err == OK:
		err = ResourceSaver.save(packed, path)
	if err != OK:
		push_error("Could not save %s: %s" % [path, error_string(err)])
	(map["root"] as Node).free()


static func tile_center(x: int, y: int) -> Vector2:
	return Vector2(x * T + T / 2.0, y * T + T / 2.0)


static func tile_feet(x: int, y: int) -> Vector2:
	return Vector2(x * T + T / 2.0, y * T + T - 4)


func _dialogue(speaker: String, texts: Array, choices_on_last: PackedStringArray = PackedStringArray()) -> DialogueData:
	var data := DialogueData.new()
	for i: int in texts.size():
		var line := DialogueLine.new()
		line.speaker = speaker
		line.text = texts[i]
		if i == texts.size() - 1:
			line.choices = choices_on_last
		data.lines.append(line)
	return data


# --- Test field (80 x 50) ---

func _build_field(ts: TileSet) -> void:
	var W := 80
	var H := 50
	var map := _new_map("TestField", &"test_field", "Cánh đồng thử nghiệm", &"xuan", ts)
	var g: TileMapLayer = map["ground"]
	var d: TileMapLayer = map["decor"]
	var blocked := {}  # tiles where trees must not be placed

	for y: int in H:
		for x: int in W:
			var r := rng.randf()
			g.set_cell(Vector2i(x, y), 0, G1 if r < 0.7 else (G2 if r < 0.95 else GF))
	# Border
	for y: int in H:
		for x: int in W:
			if x < 2 or y < 2 or x >= W - 2 or y >= H - 2:
				g.set_cell(Vector2i(x, y), 0, ROCK if rng.randf() < 0.6 else BUSH)
	# River with two bridges
	for y: int in range(2, H - 2):
		for x: int in range(44, 47):
			var bridge := (y == 24 or y == 25) or (y == 40 or y == 41)
			g.set_cell(Vector2i(x, y), 0, BRIDGE if bridge else WATER)
			blocked[Vector2i(x, y)] = true
	# Paths
	for x: int in range(4, 74):
		for y: int in [24, 25]:
			if x < 44 or x > 46:
				g.set_cell(Vector2i(x, y), 0, P1 if rng.randf() < 0.7 else P2)
	for y: int in range(13, 24):
		for x: int in [11, 12]:
			g.set_cell(Vector2i(x, y), 0, P1 if rng.randf() < 0.7 else P2)
	for y: int in range(26, 33):
		for x: int in [24, 25]:
			g.set_cell(Vector2i(x, y), 0, P1 if rng.randf() < 0.7 else P2)
	for y: int in range(26, 41):
		for x: int in [60, 61]:
			g.set_cell(Vector2i(x, y), 0, P1 if rng.randf() < 0.7 else P2)
	# House (roof + front wall), door placed as a prop
	for y: int in range(7, 11):
		for x: int in range(8, 16):
			g.set_cell(Vector2i(x, y), 0, ROOF)
	for y: int in range(11, 13):
		for x: int in range(8, 16):
			g.set_cell(Vector2i(x, y), 0, WALL)
	# Monster garden fences (with gaps)
	for x: int in range(50, 76):
		if x % 9 != 0:
			g.set_cell(Vector2i(x, 6), 0, FENCE)
			g.set_cell(Vector2i(x, 45), 0, FENCE)
	# Scattered rocks east
	for i: int in 14:
		var c := Vector2i(rng.randi_range(49, 76), rng.randi_range(8, 43))
		if abs(c.y - 24) > 1 and abs(c.x - 60) > 1:
			g.set_cell(c, 0, ROCK)
	# Decor patches
	for i: int in 40:
		var cx := rng.randi_range(3, 76)
		var cy := rng.randi_range(3, 46)
		for j: int in rng.randi_range(2, 6):
			var c := Vector2i(cx + rng.randi_range(-2, 2), cy + rng.randi_range(-2, 2))
			if g.get_cell_atlas_coords(c) in [G1, G2, GF]:
				d.set_cell(c, 0, TALL if rng.randf() < 0.6 else FLOWERS)

	# Clear zones (no trees)
	var clear_rects: Array[Rect2i] = [
		Rect2i(5, 5, 13, 11),    # house
		Rect2i(3, 19, 30, 17),   # spawn + interaction + dummy zone
		Rect2i(3, 22, 74, 6),    # main path corridor
		Rect2i(9, 12, 6, 13),    # path to house
		Rect2i(47, 3, 31, 45),   # monster garden
	]
	# Trees in the west half
	var placed := 0
	var attempts := 0
	while placed < 70 and attempts < 2000:
		attempts += 1
		var c := Vector2i(rng.randi_range(3, 42), rng.randi_range(3, 46))
		var ok := not blocked.has(c) and g.get_cell_atlas_coords(c) in [G1, G2, GF]
		for r: Rect2i in clear_rects:
			if r.has_point(c):
				ok = false
		if ok:
			blocked[c] = true
			for n: Vector2i in [c + Vector2i(1, 0), c + Vector2i(-1, 0), c + Vector2i(0, 1), c + Vector2i(0, -1)]:
				blocked[n] = true
			_add(map, S_TREE, tile_feet(c.x, c.y), "Tree%d" % placed)
			placed += 1

	# Spawn points
	_marker(map, "start", tile_center(7, 24) + Vector2(0, 16))
	_marker(map, "from_house", Vector2(12 * T, 13 * T + 22))

	# Interaction zone
	_add(map, S_DOOR, Vector2(12 * T, 13 * T), "HouseDoor", {"target_map": HOUSE_PATH, "target_spawn": &"entrance"})
	_add(map, S_SIGN, tile_feet(9, 22), "SignControls", {
		"title": "Biển hướng dẫn",
		"lines": PackedStringArray([
			"WASD / mũi tên: di chuyển. J: đánh (3 nhịp). K, L: kỹ năng. Space: né.",
			"1 / 2 hoặc Q: đổi nhân vật. E: tương tác. Esc: tạm dừng.",
			"F5 lưu nhanh, F9 tải nhanh. F3: bảng debug. Phím ` : console.",
		])})
	_add(map, S_CHEST, tile_feet(18, 19), "ChestHerbs", {"item": load("res://data/items/herb.tres"), "count": 3})
	var villager_dialogue := _dialogue("Bác nông dân", [
		"Chào cháu! Đây là cánh đồng thử nghiệm.",
		"Phía đông, qua cây cầu, là vườn quái: sói, heo rừng và quạ hoang.",
		"Cháu muốn nghe mẹo đánh nhau không?",
	], PackedStringArray(["Có ạ!", "Thôi, cháu tự lo."]))
	_add(map, S_NPC, tile_feet(16, 26), "Villager", {"display_name": "Bác nông dân", "dialogue": villager_dialogue, "face_direction": Vector2.LEFT})
	for i: int in 5:
		_add(map, S_POT, tile_feet(20 + i % 3, 21 + i / 3) + Vector2(rng.randf_range(-6, 6), 0), "Pot%d" % i)
	_add(map, S_SIGN, tile_feet(22, 31), "SignDummy", {
		"title": "Bù nhìn tập",
		"lines": PackedStringArray(["Đánh thoải mái! Bù nhìn tự hồi máu sau vài giây.", "Thử combo, kỹ năng, và xem số sát thương."])})
	_add(map, S_ENEMY, tile_feet(25, 33), "TrainingDummy", {"def": load("res://data/enemies/dummy.tres")})
	_add(map, S_SIGN, tile_feet(42, 22), "SignBridge", {
		"title": "Biển cảnh báo",
		"lines": PackedStringArray(["Phía đông: VƯỜN QUÁI. Cẩn thận!"])})

	# Monster garden
	_add_spawner(map, tile_center(56, 14), "WolfPack", "wolf", 4, 60.0)
	_add_spawner(map, tile_center(67, 30), "Boars", "boar", 2, 50.0)
	_add_spawner(map, tile_center(56, 36), "Crows", "crow", 3, 60.0)
	_add_spawner(map, tile_center(71, 41), "WolvesSouth", "wolf", 2, 40.0)
	_add(map, S_CHEST, tile_feet(73, 9), "ChestReward", {"item": load("res://data/items/coin.tres"), "count": 50})
	_save(map, FIELD_PATH)


# --- House interior (16 x 12), cold palette to test world switching ---

func _build_house(ts: TileSet) -> void:
	var W := 16
	var H := 12
	var map := _new_map("TestHouse", &"test_house", "Căn phòng xám", &"thuc", ts)
	(map["root"] as Node).set("default_spawn", &"entrance")
	var g: TileMapLayer = map["ground"]
	for y: int in H:
		for x: int in W:
			var wall := x == 0 or x == W - 1 or y <= 1 or y == H - 1
			g.set_cell(Vector2i(x, y), 0, IWALL if wall else WOOD)
	# Doorway gap in the bottom wall
	g.set_cell(Vector2i(7, H - 1), 0, WOOD)
	g.set_cell(Vector2i(8, H - 1), 0, WOOD)
	_add(map, S_DOOR, Vector2(8 * T, H * T), "ExitDoor", {"target_map": FIELD_PATH, "target_spawn": &"from_house"})
	_marker(map, "entrance", Vector2(8 * T, (H - 2) * T + 8))
	var elder_dialogue := _dialogue("Bà cụ", [
		"Căn phòng này lạnh và xám, khác hẳn ngoài kia nhỉ?",
		"Đây là thử nghiệm bảng màu \"Thực\". Ra ngoài sẽ thấy màu \"Xuân\".",
	])
	_add(map, S_NPC, tile_feet(4, 4), "Elder", {
		"display_name": "Bà cụ", "dialogue": elder_dialogue,
		"sprite_sheet": load("res://assets/sprites/characters/npc_elder/npc_elder_walk.png")})
	_add(map, S_CHEST, tile_feet(12, 3), "ChestKey", {"item": load("res://data/items/old_key.tres"), "count": 1})
	_add(map, S_POT, tile_feet(13, 8), "Pot0")
	_add(map, S_POT, tile_feet(14, 8), "Pot1")
	_save(map, HOUSE_PATH)
