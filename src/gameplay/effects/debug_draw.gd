class_name DebugDraw
extends RefCounted
## Draws the collision shapes of a CanvasItem's CollisionShape2D children (debug hitboxes).


static func draw_shapes(item: CanvasItem, color: Color) -> void:
	for child: Node in item.get_children():
		var cs := child as CollisionShape2D
		if cs == null or cs.shape == null:
			continue
		item.draw_set_transform(cs.position, cs.rotation, Vector2.ONE)
		if cs.shape is RectangleShape2D:
			var size: Vector2 = (cs.shape as RectangleShape2D).size
			item.draw_rect(Rect2(-size * 0.5, size), color)
		elif cs.shape is CircleShape2D:
			item.draw_circle(Vector2.ZERO, (cs.shape as CircleShape2D).radius, color)
		elif cs.shape is CapsuleShape2D:
			var cap := cs.shape as CapsuleShape2D
			item.draw_rect(Rect2(-cap.radius, -cap.height * 0.5, cap.radius * 2.0, cap.height), color)
	item.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
