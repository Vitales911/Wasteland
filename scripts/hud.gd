extends CanvasLayer
## Интерфейс: шкалы активного персонажа, список перков, миникарта (правый верхний угол),
## переключатель персонажей и панель задач.

const PerkRowScene := preload("res://scenes/perk_row.tscn")

var rows := {}
var _t := 0.0
var _hint_left := 0.0
const DEFAULT_HINT := "WASD — идти · Shift — бег · E — действие · 1/2/3, Tab — смена персонажа · колесо — масштаб"

@onready var switch_btns: Array = [%Btn1, %Btn2, %Btn3]

func _ready() -> void:
	%MapViewport.world_2d = get_viewport().world_2d
	_build_perk_list()
	_fill_perk_select()
	for i in switch_btns.size():
		switch_btns[i].pressed.connect(Game.switch_to.bind(i))
	%StopBtn.pressed.connect(func(): Game.active.tasks.stop())
	%ChopBtn.pressed.connect(func(): Game.active.tasks.start_work("tree"))
	%MineBtn.pressed.connect(func(): Game.active.tasks.start_work("rock"))
	%BerryBtn.pressed.connect(func(): Game.active.tasks.start_work("bush"))
	%ReadBtn.pressed.connect(func(): Game.active.tasks.start_read())
	%SpearBtn.pressed.connect(func(): Game.active.tasks.start_craft("spear"))
	%MealBtn.pressed.connect(func(): Game.active.tasks.start_craft("meal"))
	%EatBtn.pressed.connect(func(): Game.active.eat_meal())
	%TrainBtn.pressed.connect(func(): Game.active.tasks.start_train(_selected_perk()))
	%LearnBtn.pressed.connect(_on_learn)
	Game.active_changed.connect(_on_active_changed)
	%HintLabel.text = DEFAULT_HINT
	if Game.active != null:
		_on_active_changed(Game.active)

func _build_perk_list() -> void:
	var prev_cat := ""
	for p in Perks.LIST:
		var cat: String = p.cat
		var id: String = p.id
		if cat != prev_cat:
			var header := Label.new()
			header.text = "— %s —" % Perks.CATEGORIES[cat]
			header.modulate = Color(1.0, 0.85, 0.4)
			%PerkList.add_child(header)
			prev_cat = cat
		var row = PerkRowScene.instantiate()
		%PerkList.add_child(row)
		row.setup(id)
		rows[id] = row

func _fill_perk_select() -> void:
	for p in Perks.LIST:
		var cat: String = p.cat
		var id: String = p.id
		%PerkSelect.add_item("[%s] %s" % [Perks.CATEGORIES[cat], Perks.name_of(id)])
		%PerkSelect.set_item_metadata(%PerkSelect.item_count - 1, id)

func _selected_perk() -> String:
	var id: String = %PerkSelect.get_item_metadata(%PerkSelect.selected)
	return id

func _on_active_changed(c) -> void:
	%TeacherSelect.clear()
	for s in Game.survivors:
		if s != c:
			%TeacherSelect.add_item(s.display_name)
			%TeacherSelect.set_item_metadata(%TeacherSelect.item_count - 1, s)
	_refresh()

func _on_learn() -> void:
	var c = Game.active
	var idx: int = %TeacherSelect.selected
	if idx < 0:
		return
	var teacher = %TeacherSelect.get_item_metadata(idx)
	var perk := _selected_perk()
	var teacher_level: float = teacher.stats.perks[perk]
	var my_level: float = c.stats.perks[perk]
	if teacher_level - 3.0 <= my_level:
		_hint("%s знает «%s» не лучше тебя — учиться нечему" % [teacher.display_name, Perks.name_of(perk)])
		return
	c.tasks.start_learn(teacher, perk)

func _hint(text: String) -> void:
	%HintLabel.text = text
	_hint_left = 4.0

func _process(delta: float) -> void:
	if _hint_left > 0.0:
		_hint_left -= delta
		if _hint_left <= 0.0:
			%HintLabel.text = DEFAULT_HINT
	_t += delta
	if _t < 0.1:
		return
	_t = 0.0
	_refresh()

func _refresh() -> void:
	var c = Game.active
	if c == null:
		return
	var s: Stats = c.stats
	%NameLabel.text = "%s  ·  уровень %d" % [c.display_name, s.level]
	%HealthBar.max_value = s.max_health
	%HealthBar.value = s.health
	%HealthVal.text = "%d/%d" % [s.health, s.max_health]
	%StaminaBar.max_value = s.max_stamina
	%StaminaBar.value = s.stamina
	%StaminaVal.text = "%d/%d" % [s.stamina, s.max_stamina]
	%XpBar.max_value = s.xp_to_next()
	%XpBar.value = s.xp
	%XpVal.text = "%d/%d" % [s.xp, s.xp_to_next()]
	var inv: Dictionary = s.inventory
	%InfoLabel.text = "Монеты: %d\nДерево %d · Камень %d · Ягоды %d\nКопья %d · Пайки %d · Книг: %d\nЗадача: %s" % [
		s.money, inv["wood"], inv["stone"], inv["berries"], inv["spear"], inv["meal"], s.books.size(), c.tasks.status]
	for id in rows:
		rows[id].set_value(s.perks[id])
	for i in switch_btns.size():
		if i >= Game.survivors.size():
			break
		var sv = Game.survivors[i]
		switch_btns[i].text = "%d · %s  ♥%d\n%s" % [i + 1, sv.display_name, sv.stats.health, sv.tasks.status]
		switch_btns[i].modulate = Color(1.0, 0.95, 0.5) if sv == c else Color.WHITE
