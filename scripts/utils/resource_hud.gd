class_name ResourceHUD
extends VBoxContainer

## 资源 HUD — 显示当前资源数量

var _labels: Dictionary = {}

func _ready():
	ResourceManager.resource_changed.connect(_on_resource_changed)
	# 初始化显示
	for key in ResourceManager.inventory:
		_on_resource_changed(key, ResourceManager.inventory[key])

func _on_resource_changed(item_id: String, amount: int):
	var label: Label
	if _labels.has(item_id):
		label = _labels[item_id]
	else:
		label = Label.new()
		label.add_theme_color_override("font_color", Color.WHITE)
		label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_labels[item_id] = label
		add_child(label)

	label.text = "%s: %d" % [item_id, amount]
