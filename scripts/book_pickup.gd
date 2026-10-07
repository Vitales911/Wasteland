extends Area2D
class_name BookPickup
## Книга/журнал на земле. Подбирается при касании персонажем (сигнал body_entered).

@export var perk_id := "first_aid"
@export var cap := 40.0        # до какого уровня перка книга может научить
@export var title := "Книга"

func _ready() -> void:
	add_to_group("book")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is Survivor:
		body.stats.books.append({"perk": perk_id, "cap": cap, "title": title})
		body.stats.changed.emit()
		queue_free()
