class_name DepthIndicator
extends UAProgressBar

func _ready():
	EventBus.submarine_depth_changed.connect(_on_depth_changed)

func _on_depth_changed(current: float, max_d: float):
	update_value(current, max_d)
