extends Node2D

func _ready() -> void:
	# Маркеры миникарты лежат на слое видимости 2: основной экран их не рисует,
	# а SubViewport миникарты (маска по умолчанию — все слои) рисует.
	get_viewport().canvas_cull_mask = 0xFFFFFFFD

func _process(_delta: float) -> void:
	pass
