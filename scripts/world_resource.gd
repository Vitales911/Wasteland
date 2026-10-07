extends StaticBody2D
class_name WorldResource
## Дерево, камень или куст: у них есть запас "ударов"; когда он кончается — объект исчезает.

@export var kind := "tree"
@export var amount := 6

func take() -> bool:
	amount -= 1
	var t := create_tween()
	t.tween_property(self, "modulate", Color(1.5, 1.5, 1.5), 0.06)
	t.tween_property(self, "modulate", Color.WHITE, 0.10)
	if amount <= 0:
		queue_free()
		return true
	return false
