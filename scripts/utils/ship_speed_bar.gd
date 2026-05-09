class_name ShipSpeedBar
extends UAProgressBar

func _ready():
	EventBus.ship_speed_changed.connect(_on_speed_changed)

func _on_speed_changed(current: float, min_s: float, max_s: float):
	update_value(current, max_s)
