extends GutTest
## Pure pieces added in the second backbone pass.


func test_token_pool_limits_and_is_idempotent() -> void:
	var pool := TokenPool.new(2)
	assert_true(pool.try_acquire(1))
	assert_true(pool.try_acquire(1), "same holder twice is fine")
	assert_true(pool.try_acquire(2))
	assert_false(pool.try_acquire(3), "capacity reached")
	pool.release(1)
	assert_true(pool.try_acquire(3))
	assert_eq(pool.in_use(), 2)


func test_token_pool_prunes_dead_holders() -> void:
	var pool := TokenPool.new(1)
	pool.try_acquire(7)
	pool.prune(func(id: int) -> bool: return id != 7)
	assert_eq(pool.in_use(), 0)


func test_camera_fit_bounds_centers_small_rooms() -> void:
	var room := Rect2(0, 0, 512, 384)
	var fitted := GameCamera.fit_bounds(room, Vector2(640, 360))
	assert_eq(fitted.size.x, 640.0)
	assert_eq(fitted.get_center().x, room.get_center().x, "equal bars left and right")
	assert_eq(fitted.size.y, 384.0, "taller than the view: untouched")


func test_camera_fit_bounds_keeps_big_maps() -> void:
	var map := Rect2(0, 0, 2560, 1600)
	assert_eq(GameCamera.fit_bounds(map, Vector2(640, 360)), map)


func test_playtime_format() -> void:
	assert_eq(SlotList.format_playtime(0.0), "0:00:00")
	assert_eq(SlotList.format_playtime(3725.0), "1:02:05")
