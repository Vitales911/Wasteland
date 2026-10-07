extends Node
## Автозагрузка "Game": список персонажей и переключение активного.

signal active_changed(survivor)

var survivors: Array = []
var active = null

func register(s) -> void:
	survivors.append(s)
	if active == null:
		set_active(s)

func switch_to(i: int) -> void:
	if i >= 0 and i < survivors.size():
		set_active(survivors[i])

func switch_next() -> void:
	if survivors.is_empty():
		return
	var i := survivors.find(active)
	switch_to((i + 1) % survivors.size())

func set_active(s) -> void:
	if active != null:
		active.is_active = false
	active = s
	active.is_active = true
	active_changed.emit(s)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_1"):
		switch_to(0)
	elif event.is_action_pressed("switch_2"):
		switch_to(1)
	elif event.is_action_pressed("switch_3"):
		switch_to(2)
	elif event.is_action_pressed("switch_next"):
		switch_next()
