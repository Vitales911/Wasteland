extends Camera2D
## Камера следует за активным персонажем; колесо мыши — масштаб.

func _process(_delta: float) -> void:
	if Game.active != null:
		global_position = Game.active.global_position

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = (zoom * 1.1).clamp(Vector2(0.6, 0.6), Vector2(3, 3))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = (zoom / 1.1).clamp(Vector2(0.6, 0.6), Vector2(3, 3))
