extends HBoxContainer

func setup(id: String) -> void:
	$NameLabel.text = Perks.name_of(id)
	tooltip_text = Perks.by_id[id].desc

func set_value(v: float) -> void:
	$Bar.value = v
	$ValueLabel.text = str(int(v))
