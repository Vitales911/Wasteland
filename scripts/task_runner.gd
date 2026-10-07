extends Node
class_name TaskRunner
## Автономные задачи персонажа. Survivor каждый physics-кадр вызывает tick(delta)
## и получает желаемую скорость. Работает и для неактивных персонажей.

enum T { IDLE, WORK, READ, TRAIN, CRAFT, LEARN }

const WORK := {
	"tree": {"item": "wood", "perk": "lumberjack", "stamina": 6.0, "xp": 3.0, "title": "Рубит дерево"},
	"rock": {"item": "stone", "perk": "mining", "stamina": 7.0, "xp": 3.0, "title": "Добывает камень"},
	"bush": {"item": "berries", "perk": "foraging", "stamina": 2.0, "xp": 2.5, "title": "Собирает ягоды"},
}
const ITEM_SOURCE := {"wood": "tree", "stone": "rock", "berries": "bush"}
const RECIPES := {
	"spear": {"name": "Копьё", "needs": {"wood": 2, "stone": 1}, "result": "spear", "perk": "carpentry", "time": 3.0, "stamina": 4.0},
	"meal": {"name": "Паёк", "needs": {"berries": 3}, "result": "meal", "perk": "cooking", "time": 2.5, "stamina": 2.0},
}
const REACH := 40.0
const PRACTICE_CAP := 60.0   # практикой выше этого уровня не научиться — нужны книги или учитель

var task: int = T.IDLE
var status := "Свободен"
var work_kind := ""
var recipe_id := ""
var perk_id := ""
var teacher: Survivor = null
var target: Node2D = null
var timer := 0.0
var resting := false

@onready var me: Survivor = get_parent() as Survivor

# ---------- запуск задач ----------
func stop(msg: String = "Свободен") -> void:
	task = T.IDLE
	target = null
	resting = false
	status = msg

func start_work(kind: String) -> void:
	stop()
	task = T.WORK
	work_kind = kind
	status = WORK[kind].title

func start_read() -> void:
	stop()
	task = T.READ
	status = "Читает"

func start_train(perk: String) -> void:
	stop()
	task = T.TRAIN
	perk_id = perk
	status = "Тренируется"

func start_craft(recipe: String) -> void:
	stop()
	task = T.CRAFT
	recipe_id = recipe
	status = "Мастерит"

func start_learn(from: Survivor, perk: String) -> void:
	stop()
	task = T.LEARN
	teacher = from
	perk_id = perk
	status = "Идёт к учителю"

# ---------- главный цикл ----------
func tick(delta: float) -> Vector2:
	if task == T.IDLE:
		return Vector2.ZERO
	if task in [T.WORK, T.TRAIN, T.CRAFT] and _check_rest():
		return Vector2.ZERO
	match task:
		T.WORK: return _tick_work(delta)
		T.READ: return _tick_read(delta)
		T.TRAIN: return _tick_train(delta)
		T.CRAFT: return _tick_craft(delta)
		T.LEARN: return _tick_learn(delta)
	return Vector2.ZERO

func _check_rest() -> bool:
	var s := me.stats
	if resting:
		if s.stamina >= s.max_stamina * 0.8:
			resting = false
		else:
			status = "Отдыхает (нет сил)"
			return true
	elif s.stamina < 5.0:
		resting = true
		status = "Отдыхает (нет сил)"
		return true
	return false

# ---------- помощники ----------
func _approach(pos: Vector2, dist: float) -> Vector2:
	var d := pos - me.global_position
	if d.length() > dist:
		return d.normalized() * me.walk_speed
	return Vector2.ZERO

func _arrived(pos: Vector2, dist: float) -> bool:
	return me.global_position.distance_to(pos) <= dist

func _nearest(group: String) -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group(group):
		var node := n as Node2D
		if node.is_queued_for_deletion():
			continue
		var d := me.global_position.distance_squared_to(node.global_position)
		if d < best_d:
			best_d = d
			best = node
	return best

func _target_valid() -> bool:
	return is_instance_valid(target) and not target.is_queued_for_deletion()

## Один шаг работы: тратит выносливость, даёт предмет и опыт перка, "бьёт" ресурс.
func do_work(kind: String, node: Node2D) -> bool:
	var spec: Dictionary = WORK[kind]
	var s := me.stats
	if not s.use_stamina(spec.stamina):
		return false
	var perk_level: float = s.perks[spec.perk]
	var amount := 1 + int(perk_level / 40.0)
	s.inventory[spec.item] += amount
	s.add_perk_xp(spec.perk, spec.xp)
	(node as WorldResource).take()
	return true

# ---------- задачи ----------
func _tick_work(delta: float) -> Vector2:
	var spec: Dictionary = WORK[work_kind]
	if not _target_valid():
		target = _nearest(work_kind)
		if target == null:
			stop("Ресурсов не осталось")
			return Vector2.ZERO
	if not _arrived(target.global_position, REACH):
		status = "Идёт: " + String(spec.title).to_lower()
		return _approach(target.global_position, REACH)
	status = spec.title
	timer -= delta
	if timer <= 0.0:
		var perk_level: float = me.stats.perks[spec.perk]
		timer = 1.4 / (1.0 + perk_level / 100.0)
		do_work(work_kind, target)
	return Vector2.ZERO

func _pick_book() -> Dictionary:
	for b in me.stats.books:
		var lvl: float = me.stats.perks[b.perk]
		if lvl < float(b.cap) - 0.01:
			return b
	return {}

func _tick_read(delta: float) -> Vector2:
	var book := _pick_book()
	if book.is_empty():
		if not _target_valid():
			target = _nearest("book")
			if target == null:
				stop("Нечего читать")
				return Vector2.ZERO
		status = "Идёт за книгой"
		return _approach(target.global_position, 4.0)
	status = "Читает: " + String(book.title)
	timer -= delta
	if timer <= 0.0:
		timer = 2.0
		me.stats.add_perk_xp(book.perk, 2.5, float(book.cap))
	return Vector2.ZERO

func _tick_train(delta: float) -> Vector2:
	var s := me.stats
	var is_weapon: bool = Perks.by_id[perk_id].cat == "weapon"
	if is_weapon:
		if not _target_valid():
			target = _nearest("dummy")
			if target == null:
				stop("Нет тренировочного манекена")
				return Vector2.ZERO
		if not _arrived(target.global_position, 50.0):
			status = "Идёт к манекену"
			return _approach(target.global_position, 50.0)
	status = "Тренирует: " + Perks.name_of(perk_id)
	timer -= delta
	if timer <= 0.0:
		timer = 1.5
		if not s.use_stamina(5.0):
			return Vector2.ZERO
		var mult := 1.0
		var spear_count: int = s.inventory["spear"]
		if spear_count > 0 and perk_id in ["melee", "thrown"]:
			mult = 1.5   # использование копья ускоряет тренировку
		if not s.add_perk_xp(perk_id, 1.5 * mult, PRACTICE_CAP):
			stop("Практикой выше %d не вырасти — нужны книги или учитель" % int(PRACTICE_CAP))
	return Vector2.ZERO

func _tick_craft(delta: float) -> Vector2:
	var r: Dictionary = RECIPES[recipe_id]
	var s := me.stats
	var needs: Dictionary = r.needs
	for item in needs:
		var have: int = s.inventory[item]
		if have < int(needs[item]):
			work_kind = ITEM_SOURCE[item]   # сам добывает недостающее
			return _tick_work(delta)
	status = "Мастерит: " + String(r.name)
	timer -= delta
	if timer <= 0.0:
		var perk_level: float = s.perks[r.perk]
		timer = float(r.time) / (1.0 + perk_level / 100.0)
		if s.use_stamina(float(r.stamina)):
			for item in needs:
				s.inventory[item] -= int(needs[item])
			s.inventory[r.result] += 1
			s.add_perk_xp(r.perk, 4.0)
	return Vector2.ZERO

func _tick_learn(delta: float) -> Vector2:
	if not is_instance_valid(teacher):
		stop("Учитель недоступен")
		return Vector2.ZERO
	var s := me.stats
	var teacher_level: float = teacher.stats.perks[perk_id]
	var cap := teacher_level - 3.0
	var my_level: float = s.perks[perk_id]
	if my_level >= cap:
		stop("Учитель больше ничему не научит")
		return Vector2.ZERO
	if not _arrived(teacher.global_position, 50.0):
		status = "Идёт к учителю: " + teacher.display_name
		return _approach(teacher.global_position, 50.0)
	status = "Учится у %s: %s" % [teacher.display_name, Perks.name_of(perk_id)]
	timer -= delta
	if timer <= 0.0:
		timer = 3.0
		var price := 2 + int(teacher_level / 10.0)
		if s.money < price:
			stop("Не хватает денег на урок")
			return Vector2.ZERO
		s.money -= price
		teacher.stats.money += price
		var teaching: float = teacher.stats.perks["teaching"]
		s.add_perk_xp(perk_id, 5.0 * (1.0 + teaching / 100.0), cap)
		teacher.stats.add_perk_xp("teaching", 0.8)
	return Vector2.ZERO
