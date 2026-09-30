extends SceneTree
## Generates placeholder PNGs that follow the GDD asset spec (13.1 / 13.2).
## Run: godot --headless --path . -s res://tools/generate_placeholders.gd
## Safe to re-run; real art simply overwrites these files later.

const OUTLINE := Color(0.1, 0.07, 0.1)
const SKIN := Color(0.96, 0.8, 0.66)

var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 1234
	_characters()
	_enemies()
	_props()
	_items()
	_tiles()
	print("Placeholders generated.")
	quit()


# --- Helpers ---

func _img(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy: int in range(maxi(y, 0), mini(y + h, img.get_height())):
		for xx: int in range(maxi(x, 0), mini(x + w, img.get_width())):
			img.set_pixel(xx, yy, c)


func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for yy: int in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for xx: int in range(int(cx - rx) - 1, int(cx + rx) + 2):
			if xx < 0 or yy < 0 or xx >= img.get_width() or yy >= img.get_height():
				continue
			var dx := (xx + 0.5 - cx) / rx
			var dy := (yy + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(xx, yy, c)


func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


## Adds a 1px dark outline around opaque pixels inside the given region.
func _outline(img: Image, rx: int, ry: int, rw: int, rh: int) -> void:
	var marks: Array[Vector2i] = []
	for y: int in range(ry, ry + rh):
		for x: int in range(rx, rx + rw):
			if img.get_pixel(x, y).a > 0.1:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n := Vector2i(x, y) + d
				if n.x >= rx and n.y >= ry and n.x < rx + rw and n.y < ry + rh and img.get_pixelv(n).a > 0.5 and img.get_pixelv(n) != OUTLINE:
					marks.append(Vector2i(x, y))
					break
	for m: Vector2i in marks:
		img.set_pixelv(m, OUTLINE)


func _save(img: Image, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var err := img.save_png(path)
	if err != OK:
		push_error("Could not save %s" % path)


# --- Characters: 32x48 frames, 3 walk frames x 4 directions (down, left, right, up) ---

func _characters() -> void:
	_character_sheet("res://assets/sprites/characters/vu/vu_walk.png",
		Color(0.25, 0.42, 0.75), Color(0.12, 0.1, 0.12), Color(0.85, 0.85, 0.9))
	_character_sheet("res://assets/sprites/characters/binh_an/binh_an_walk.png",
		Color(0.35, 0.62, 0.3), Color(0.45, 0.28, 0.15), Color(0.75, 0.55, 0.3))
	_character_sheet("res://assets/sprites/characters/npc_villager/npc_villager_walk.png",
		Color(0.72, 0.52, 0.3), Color(0.25, 0.18, 0.12), Color(0.9, 0.8, 0.6))
	_character_sheet("res://assets/sprites/characters/npc_elder/npc_elder_walk.png",
		Color(0.55, 0.35, 0.55), Color(0.85, 0.85, 0.85), Color(0.95, 0.9, 0.7))


func _character_sheet(path: String, tunic: Color, hair: Color, accent: Color) -> void:
	var fw := 32
	var fh := 48
	var img := _img(fw * 3, fh * 4)
	for row: int in 4:
		for col: int in 3:
			_character_frame(img, col * fw, row * fh, row, col, tunic, hair, accent)
			_outline(img, col * fw, row * fh, fw, fh)
	_save(img, path)


func _character_frame(img: Image, ox: int, oy: int, dir: int, frame: int, tunic: Color, hair: Color, accent: Color) -> void:
	var step: int = [-2, 0, 2][frame]
	var pants := tunic.darkened(0.45)
	# Legs
	_rect(img, ox + 11, oy + 36 + mini(step, 0), 4, 9 - absi(mini(step, 0)), pants)
	_rect(img, ox + 17, oy + 36 - maxi(step, 0), 4, 9 - maxi(step, 0), pants)
	_rect(img, ox + 10, oy + 44 + mini(step, 0), 5, 2, OUTLINE.lightened(0.2))
	_rect(img, ox + 17, oy + 44 - maxi(step, 0), 5, 2, OUTLINE.lightened(0.2))
	# Body
	_rect(img, ox + 9, oy + 23, 14, 14, tunic)
	_rect(img, ox + 9, oy + 32, 14, 2, accent.darkened(0.2))
	_rect(img, ox + 10, oy + 24, 12, 2, tunic.lightened(0.2))
	# Arms (swing opposite to legs)
	var arm_swing: int = -step
	if dir == 0 or dir == 3:
		_rect(img, ox + 6, oy + 24 + maxi(arm_swing, 0), 3, 11, tunic.darkened(0.15))
		_rect(img, ox + 23, oy + 24 + maxi(-arm_swing, 0), 3, 11, tunic.darkened(0.15))
		_rect(img, ox + 6, oy + 34 + maxi(arm_swing, 0), 3, 2, SKIN)
		_rect(img, ox + 23, oy + 34 + maxi(-arm_swing, 0), 3, 2, SKIN)
	else:
		var ax: int = ox + 14 + arm_swing
		_rect(img, ax, oy + 24, 4, 10, tunic.darkened(0.15))
		_rect(img, ax, oy + 33, 4, 2, SKIN)
	# Head
	_ellipse(img, ox + 16, oy + 15, 8, 8, SKIN)
	# Hair
	match dir:
		0:
			_ellipse(img, ox + 16, oy + 11, 8.5, 5.5, hair)
			_rect(img, ox + 8, oy + 10, 3, 7, hair)
			_rect(img, ox + 21, oy + 10, 3, 7, hair)
			_rect(img, ox + 12, oy + 15, 2, 3, OUTLINE)
			_rect(img, ox + 18, oy + 15, 2, 3, OUTLINE)
			_rect(img, ox + 15, oy + 20, 2, 1, SKIN.darkened(0.3))
		1:
			_ellipse(img, ox + 17, oy + 11, 8.5, 6, hair)
			_rect(img, ox + 18, oy + 10, 6, 10, hair)
			_rect(img, ox + 11, oy + 15, 2, 3, OUTLINE)
		2:
			_ellipse(img, ox + 15, oy + 11, 8.5, 6, hair)
			_rect(img, ox + 8, oy + 10, 6, 10, hair)
			_rect(img, ox + 19, oy + 15, 2, 3, OUTLINE)
		3:
			_ellipse(img, ox + 16, oy + 14, 8.5, 8.5, hair)
	# Scarf / accent
	_rect(img, ox + 10, oy + 22, 12, 2, accent)


# --- Enemies ---

func _enemies() -> void:
	_quadruped_sheet("res://assets/sprites/enemies/wolf/wolf_walk.png", 32, 32,
		Color(0.55, 0.57, 0.62), Color(0.85, 0.85, 0.88), false)
	_quadruped_sheet("res://assets/sprites/enemies/boar/boar_walk.png", 40, 32,
		Color(0.5, 0.33, 0.22), Color(0.95, 0.92, 0.8), true)
	_crow_sheet("res://assets/sprites/enemies/crow/crow_walk.png")
	_dummy_sheet("res://assets/sprites/enemies/dummy/dummy_walk.png")


func _quadruped_sheet(path: String, fw: int, fh: int, fur: Color, belly: Color, tusks: bool) -> void:
	var img := _img(fw * 3, fh * 4)
	for row: int in 4:
		for col: int in 3:
			var ox := col * fw
			var oy := row * fh
			var step: int = [-1, 0, 1][col]
			var cx := fw / 2.0
			if row == 1 or row == 2:
				var face := -1.0 if row == 1 else 1.0
				# legs
				for i: int in 4:
					var lx := int(cx - fw * 0.3 + i * fw * 0.18)
					var lift: int = step if i % 2 == 0 else -step
					_rect(img, ox + lx, oy + fh - 9 - maxi(lift, 0), 3, 8, fur.darkened(0.3))
				_ellipse(img, ox + cx, oy + fh - 13, fw * 0.36, 7, fur)
				_ellipse(img, ox + cx, oy + fh - 10, fw * 0.26, 3, belly)
				var hx := cx + face * fw * 0.32
				_ellipse(img, ox + hx, oy + fh - 17, 6, 5.5, fur)
				_rect(img, ox + int(hx + face * 4) - 1, oy + fh - 17, 3, 3, fur.darkened(0.2))
				_px(img, ox + int(hx + face * 2), oy + fh - 19, Color(0.9, 0.15, 0.1))
				# ear
				_rect(img, ox + int(hx - face * 2), oy + fh - 24, 3, 4, fur.darkened(0.25))
				# tail
				_rect(img, ox + int(cx - face * fw * 0.42) - 1, oy + fh - 18, 3, 5, fur.darkened(0.15))
				if tusks:
					_rect(img, ox + int(hx + face * 5), oy + fh - 14, 2, 3, belly)
			else:
				var facing_down := row == 0
				for i: int in 2:
					var lift: int = step if i == 0 else -step
					_rect(img, ox + int(cx - 6 + i * 9), oy + fh - 8 - maxi(lift, 0), 3, 7, fur.darkened(0.3))
				_ellipse(img, ox + cx, oy + fh - 14, fw * 0.28, 9, fur)
				if facing_down:
					_ellipse(img, ox + cx, oy + fh - 20, 6.5, 6, fur.lightened(0.05))
					_px(img, ox + int(cx) - 3, oy + fh - 21, Color(0.9, 0.15, 0.1))
					_px(img, ox + int(cx) + 2, oy + fh - 21, Color(0.9, 0.15, 0.1))
					_rect(img, ox + int(cx) - 1, oy + fh - 17, 2, 2, OUTLINE)
					if tusks:
						_rect(img, ox + int(cx) - 5, oy + fh - 17, 2, 3, belly)
						_rect(img, ox + int(cx) + 3, oy + fh - 17, 2, 3, belly)
				else:
					_rect(img, ox + int(cx) - 1, oy + fh - 8, 3, 5, fur.darkened(0.15))
				_rect(img, ox + int(cx) - 6, oy + fh - 27, 3, 4, fur.darkened(0.25))
				_rect(img, ox + int(cx) + 3, oy + fh - 27, 3, 4, fur.darkened(0.25))
			_outline(img, ox, oy, fw, fh)
	_save(img, path)


func _crow_sheet(path: String) -> void:
	var fw := 24
	var fh := 24
	var img := _img(fw * 3, fh * 4)
	var body := Color(0.18, 0.16, 0.24)
	for row: int in 4:
		for col: int in 3:
			var ox := col * fw
			var oy := row * fh
			var flap: int = [-4, 0, 4][col]
			_ellipse(img, ox + 12, oy + 13, 5, 4, body)
			_ellipse(img, ox + 6, oy + 12 + flap * 0.5, 5, 2.5, body.lightened(0.1))
			_ellipse(img, ox + 18, oy + 12 + flap * 0.5, 5, 2.5, body.lightened(0.1))
			var hx := 12 + (-3 if row == 1 else (3 if row == 2 else 0))
			_ellipse(img, ox + hx, oy + 9, 3, 3, body)
			if row != 3:
				_px(img, ox + hx - 1, oy + 8, Color(1, 0.8, 0.2))
				_px(img, ox + hx + 1, oy + 8, Color(1, 0.8, 0.2))
				_rect(img, ox + hx, oy + 10, 1 if row == 0 else 2, 2, Color(0.95, 0.7, 0.2))
			_outline(img, ox, oy, fw, fh)
	_save(img, path)


func _dummy_sheet(path: String) -> void:
	var fw := 32
	var fh := 40
	var img := _img(fw * 3, fh * 4)
	for row: int in 4:
		for col: int in 3:
			var ox := col * fw
			var oy := row * fh
			_rect(img, ox + 15, oy + 20, 3, 19, Color(0.5, 0.35, 0.2))
			_rect(img, ox + 7, oy + 20, 18, 3, Color(0.5, 0.35, 0.2))
			_ellipse(img, ox + 16, oy + 18, 7, 8, Color(0.85, 0.75, 0.4))
			_ellipse(img, ox + 16, oy + 8, 5, 5, Color(0.85, 0.75, 0.4))
			_ellipse(img, ox + 16, oy + 18, 3, 3, Color(0.85, 0.2, 0.2))
			_outline(img, ox, oy, fw, fh)
	_save(img, path)


# --- Props ---

func _props() -> void:
	var wood := Color(0.55, 0.36, 0.2)
	var gold := Color(0.95, 0.78, 0.25)
	# Chest closed
	var img := _img(24, 20)
	_rect(img, 2, 6, 20, 13, wood)
	_rect(img, 2, 3, 20, 5, wood.lightened(0.15))
	_rect(img, 2, 8, 20, 2, gold)
	_rect(img, 10, 7, 4, 5, gold.lightened(0.2))
	_outline(img, 0, 0, 24, 20)
	_save(img, "res://assets/sprites/props/chest_closed.png")
	# Chest open
	img = _img(24, 20)
	_rect(img, 2, 8, 20, 11, wood)
	_rect(img, 3, 8, 18, 3, Color(0.2, 0.12, 0.08))
	_rect(img, 6, 9, 12, 2, gold)
	_rect(img, 2, 1, 20, 5, wood.lightened(0.15))
	_rect(img, 2, 5, 20, 2, gold)
	_outline(img, 0, 0, 24, 20)
	_save(img, "res://assets/sprites/props/chest_open.png")
	# Sign
	img = _img(20, 24)
	_rect(img, 9, 12, 3, 12, wood.darkened(0.2))
	_rect(img, 1, 2, 18, 11, wood.lightened(0.1))
	for i: int in 3:
		_rect(img, 4, 5 + i * 3, 12, 1, wood.darkened(0.35))
	_outline(img, 0, 0, 20, 24)
	_save(img, "res://assets/sprites/props/sign.png")
	# Pot
	img = _img(16, 18)
	_ellipse(img, 8, 11, 6.5, 6, Color(0.78, 0.45, 0.3))
	_rect(img, 4, 2, 8, 4, Color(0.7, 0.4, 0.27))
	_rect(img, 5, 3, 6, 1, Color(0.3, 0.15, 0.1))
	_rect(img, 3, 10, 10, 1, Color(0.9, 0.7, 0.45))
	_outline(img, 0, 0, 16, 18)
	_save(img, "res://assets/sprites/props/pot.png")
	# Door
	img = _img(32, 40)
	_rect(img, 2, 2, 28, 38, Color(0.4, 0.4, 0.45))
	_rect(img, 5, 5, 22, 35, wood)
	for i: int in 3:
		_rect(img, 5 + i * 8, 5, 1, 35, wood.darkened(0.3))
	_rect(img, 22, 22, 2, 3, gold)
	_outline(img, 0, 0, 32, 40)
	_save(img, "res://assets/sprites/props/door.png")
	# Tree
	img = _img(48, 64)
	_rect(img, 20, 38, 8, 24, Color(0.45, 0.3, 0.18))
	_ellipse(img, 24, 26, 20, 18, Color(0.2, 0.5, 0.25))
	_ellipse(img, 18, 20, 11, 10, Color(0.3, 0.62, 0.3))
	_ellipse(img, 30, 24, 10, 9, Color(0.26, 0.58, 0.28))
	_ellipse(img, 22, 14, 6, 5, Color(0.45, 0.75, 0.4))
	_outline(img, 0, 0, 48, 64)
	_save(img, "res://assets/sprites/props/tree.png")


func _items() -> void:
	var img := _img(16, 16)
	_ellipse(img, 8, 8, 5.5, 5.5, Color(0.98, 0.8, 0.25))
	_ellipse(img, 8, 8, 3, 3, Color(0.85, 0.6, 0.15))
	_outline(img, 0, 0, 16, 16)
	_save(img, "res://assets/sprites/items/coin.png")
	img = _img(16, 16)
	_ellipse(img, 6, 7, 3.5, 5, Color(0.3, 0.75, 0.3))
	_ellipse(img, 10, 7, 3.5, 5, Color(0.4, 0.85, 0.35))
	_rect(img, 7, 10, 2, 5, Color(0.25, 0.5, 0.2))
	_outline(img, 0, 0, 16, 16)
	_save(img, "res://assets/sprites/items/herb.png")
	img = _img(16, 16)
	_ellipse(img, 5.5, 6.5, 3.5, 3.5, Color(0.9, 0.2, 0.3))
	_ellipse(img, 10.5, 6.5, 3.5, 3.5, Color(0.9, 0.2, 0.3))
	for y: int in range(7, 14):
		var half := 7 - (y - 7)
		_rect(img, 8 - half, y, half * 2, 1, Color(0.9, 0.2, 0.3))
	_outline(img, 0, 0, 16, 16)
	_save(img, "res://assets/sprites/items/heart.png")
	img = _img(16, 16)
	_ellipse(img, 5, 6, 3.5, 3.5, Color(0.95, 0.8, 0.3))
	_ellipse(img, 5, 6, 1.5, 1.5, Color(0, 0, 0, 0))
	_rect(img, 7, 5, 7, 2, Color(0.95, 0.8, 0.3))
	_rect(img, 11, 7, 2, 3, Color(0.95, 0.8, 0.3))
	_outline(img, 0, 0, 16, 16)
	_save(img, "res://assets/sprites/items/old_key.png")


# --- Tiles: 32x32, atlas 8 columns x 2 rows ---

func _tiles() -> void:
	var t := 32
	var img := _img(t * 8, t * 2)
	var grass := Color(0.36, 0.62, 0.3)
	_noise_tile(img, 0, 0, grass, 0.06)
	_noise_tile(img, 1, 0, grass.darkened(0.05), 0.08)
	_noise_tile(img, 2, 0, grass, 0.06)
	_flowers(img, 2 * t, 0, 5)
	_noise_tile(img, 3, 0, Color(0.7, 0.55, 0.36), 0.07)
	_noise_tile(img, 4, 0, Color(0.66, 0.51, 0.33), 0.09)
	_planks(img, 5 * t, 0, Color(0.62, 0.44, 0.28), false)
	_water(img, 6 * t, 0)
	_planks(img, 7 * t, 0, Color(0.58, 0.4, 0.24), true)
	# Row 1 (solid unless noted)
	_bricks(img, 0, t, Color(0.52, 0.52, 0.56))
	_noise_tile(img, 1, 1, grass, 0.06)
	_ellipse(img, t + 16, t + 18, 12, 10, Color(0.5, 0.5, 0.52))
	_ellipse(img, t + 13, t + 14, 6, 4, Color(0.65, 0.65, 0.68))
	_outline(img, 0 + t, t, t, t)
	_noise_tile(img, 2, 1, grass, 0.06)
	_fence(img, 2 * t, t)
	_noise_tile(img, 3, 1, grass, 0.06)
	_ellipse(img, 3 * t + 16, t + 18, 14, 12, Color(0.18, 0.45, 0.22))
	_ellipse(img, 3 * t + 12, t + 14, 7, 5, Color(0.28, 0.58, 0.3))
	_bricks(img, 4 * t, t, Color(0.72, 0.62, 0.5))
	_tall_grass(img, 5 * t, t)
	_flowers(img, 6 * t, t, 7)
	_roof(img, 7 * t, t)
	_save(img, "res://assets/tilesets/xuan_field.png")


func _noise_tile(img: Image, col: int, row: int, base: Color, amount: float) -> void:
	var t := 32
	for y: int in t:
		for x: int in t:
			var n := rng.randf_range(-amount, amount)
			img.set_pixel(col * t + x, row * t + y, Color(base.r + n, base.g + n, base.b + n * 0.5))
	for i: int in 6:
		var x := rng.randi_range(2, 29)
		var y := rng.randi_range(2, 29)
		_rect(img, col * t + x, row * t + y, 1, 2, base.darkened(0.2))


func _flowers(img: Image, ox: int, oy: int, count: int) -> void:
	var colors: Array[Color] = [Color(1, 0.9, 0.3), Color(1, 0.55, 0.7), Color(0.95, 0.95, 1)]
	for i: int in count:
		var x := rng.randi_range(3, 28)
		var y := rng.randi_range(3, 28)
		var c := colors[i % colors.size()]
		_px(img, ox + x, oy + y, c)
		_px(img, ox + x + 1, oy + y, c)
		_px(img, ox + x, oy + y + 1, c)
		_px(img, ox + x + 1, oy + y + 1, c.darkened(0.2))


func _tall_grass(img: Image, ox: int, oy: int) -> void:
	for i: int in 9:
		var x := rng.randi_range(2, 28)
		var y := rng.randi_range(12, 28)
		for h: int in rng.randi_range(4, 7):
			_px(img, ox + x + (1 if h > 3 else 0), oy + y - h, Color(0.3, 0.55 + h * 0.02, 0.25))


func _planks(img: Image, ox: int, oy: int, c: Color, horizontal: bool) -> void:
	for y: int in 32:
		for x: int in 32:
			var line := (y % 8 == 0) if horizontal else (x % 8 == 0)
			var n := rng.randf_range(-0.03, 0.03)
			img.set_pixel(ox + x, oy + y, c.darkened(0.3) if line else Color(c.r + n, c.g + n, c.b + n))


func _water(img: Image, ox: int, oy: int) -> void:
	for y: int in 32:
		for x: int in 32:
			var wave := sin((x + y * 0.5) * 0.4) * 0.03
			img.set_pixel(ox + x, oy + y, Color(0.25 + wave, 0.5 + wave, 0.78))
	for i: int in 4:
		_rect(img, ox + rng.randi_range(2, 24), oy + rng.randi_range(2, 28), 5, 1, Color(0.6, 0.8, 0.95))


func _bricks(img: Image, ox: int, oy: int, c: Color) -> void:
	for y: int in 32:
		for x: int in 32:
			var row := y / 8
			var shift := 8 if row % 2 == 1 else 0
			var mortar := y % 8 == 7 or (x + shift) % 16 == 15
			var n := rng.randf_range(-0.04, 0.04)
			img.set_pixel(ox + x, oy + y, c.darkened(0.4) if mortar else Color(c.r + n, c.g + n, c.b + n))


func _fence(img: Image, ox: int, oy: int) -> void:
	var wood := Color(0.6, 0.42, 0.25)
	_rect(img, ox + 4, oy + 10, 4, 18, wood)
	_rect(img, ox + 24, oy + 10, 4, 18, wood)
	_rect(img, ox, oy + 14, 32, 3, wood.lightened(0.1))
	_rect(img, ox, oy + 22, 32, 3, wood.lightened(0.1))


func _roof(img: Image, ox: int, oy: int) -> void:
	for y: int in 32:
		for x: int in 32:
			var stripe := y % 6 < 1
			img.set_pixel(ox + x, oy + y, Color(0.62, 0.25, 0.2).darkened(0.25) if stripe else Color(0.72, 0.3, 0.22))
