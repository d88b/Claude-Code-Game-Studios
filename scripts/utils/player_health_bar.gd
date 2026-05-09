class_name PlayerHealthBar
extends TextureProgressBar

func _ready():
	EventBus.player_health_changed.connect(_on_health_changed)

func _on_health_changed(current: float, max_val: float):
	value = current
	max_value = max_val
