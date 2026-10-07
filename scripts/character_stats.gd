extends Node
class_name Stats
## Шкалы и прогресс одного персонажа: здоровье, выносливость, опыт, перки, инвентарь.

signal changed
signal leveled_up(new_level: int)

@export var max_health := 100.0
@export var max_stamina := 100.0

var health := 100.0
var stamina := 100.0
var xp := 0.0
var level := 1
var money := 0
var perks := {}          # id перка -> уровень 0..100 (float)
var inventory := {"wood": 0, "stone": 0, "berries": 0, "spear": 0, "meal": 0}
var books: Array = []    # {"perk": id, "cap": float, "title": String}

func _ready() -> void:
	for p in Perks.LIST:
		var id: String = p.id
		perks[id] = 0.0

func xp_to_next() -> float:
	return 40.0 * level

func use_stamina(amount: float) -> bool:
	if stamina < amount:
		return false
	stamina -= amount
	return true

## Добавляет опыт перку. cap — потолок, выше которого этим способом не вырасти.
## Возвращает false, если прогресса нет (достигнут потолок).
func add_perk_xp(id: String, amount: float, cap: float = 100.0) -> bool:
	var lvl: float = perks[id]
	if lvl >= cap:
		return false
	var literacy: float = perks["literacy"]
	var gain: float = amount / (1.0 + lvl / 25.0) * (1.0 + literacy / 200.0)
	perks[id] = minf(minf(lvl + gain, cap), 100.0)
	_add_xp(gain * 4.0)
	changed.emit()
	return true

func _add_xp(amount: float) -> void:
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		max_health += 5.0
		health = max_health
		leveled_up.emit(level)
