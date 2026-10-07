extends CharacterBody2D
class_name Survivor
## Один из трёх выживших. Управляется WASD, пока активен; иначе выполняет задачу из TaskRunner.

@export var display_name := "Безымянный"
@export var body_color := Color.WHITE
@export var start_money := 20
@export var start_perks: Dictionary = {}
@export var walk_speed := 110.0
@export var sprint_speed := 190.0

var is_active := false : set = _set_active

@onready var stats: Stats = $Stats
@onready var tasks: TaskRunner = $TaskRunner
@onready var body: Polygon2D = $Body
@onready var ring: Polygon2D = $ActiveRing
@onready var name_label: Label = $NameLabel
@onready var marker: Polygon2D = $MapMarker

func _ready() -> void:
	add_to_group("survivors")
	body.color = body_color
	marker.color = body_color
	name_label.text = display_name
	stats.money = start_money
	for id in start_perks:
		stats.perks[id] = float(start_perks[id])
	ring.visible = is_active
	Game.register(self)

func _set_active(v: bool) -> void:
	is_active = v
	if ring != null:
		ring.visible = v
		marker.scale = Vector2(1.5, 1.5) if v else Vector2.ONE

func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if is_active:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var sprinting := false
	if input != Vector2.ZERO:
		if tasks.task != TaskRunner.T.IDLE:
			tasks.stop("Свободен (взят под управление)")
		sprinting = Input.is_action_pressed("sprint") and stats.stamina > 1.0
		velocity = input * (sprint_speed if sprinting else walk_speed)
	else:
		velocity = tasks.tick(delta)
	move_and_slide()
	if velocity.length() > 5.0:
		body.rotation = velocity.angle()
	_update_vitals(delta, sprinting)

func _update_vitals(delta: float, sprinting: bool) -> void:
	var moving := velocity.length() > 5.0
	if sprinting:
		stats.stamina = maxf(0.0, stats.stamina - 14.0 * delta)
	else:
		var rate := 3.0 if moving else 2.0
		if tasks.task == TaskRunner.T.IDLE or tasks.resting:
			rate = 3.0 if moving else 9.0
		stats.stamina = minf(stats.max_stamina, stats.stamina + rate * delta)
	if stats.stamina > 30.0 and stats.health < stats.max_health:
		stats.health = minf(stats.max_health, stats.health + 0.8 * delta)

func _unhandled_input(event: InputEvent) -> void:
	if is_active and event.is_action_pressed("interact"):
		_manual_work()

## Ручное действие (E): один шаг работы с ближайшим ресурсом.
func _manual_work() -> void:
	var best: Node2D = null
	var best_kind := ""
	var best_d := 50.0
	for kind in ["tree", "rock", "bush"]:
		for n in get_tree().get_nodes_in_group(kind):
			var node := n as Node2D
			if node.is_queued_for_deletion():
				continue
			var d := global_position.distance_to(node.global_position)
			if d < best_d:
				best_d = d
				best = node
				best_kind = kind
	if best != null:
		tasks.do_work(best_kind, best)

func eat_meal() -> void:
	if stats.inventory["meal"] > 0:
		stats.inventory["meal"] -= 1
		stats.health = minf(stats.max_health, stats.health + 30.0)
		stats.stamina = minf(stats.max_stamina, stats.stamina + 30.0)
		stats.changed.emit()
