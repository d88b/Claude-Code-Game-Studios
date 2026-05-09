class_name PlayerEnergyBar
extends TextureProgressBar

func _ready():
	EventBus.player_energy_changed.connect(_on_energy_changed)

func _on_energy_changed(current: float, max_val: float):
	value = current
	max_value = max_val
