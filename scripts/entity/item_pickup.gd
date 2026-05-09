class_name ItemPickup
extends Area2D

## 可拾取资源实体 — 浮动动画，靠近按 E 拾取

@export var item_data: ItemData
@export var amount: int = 1
@export var bob_speed: float = 2.0
@export var bob_height: float = 5.0

var base_y: float = 0.0
var collected: bool = false
var bob_timer: float = 0.0

func _ready():
	collision_layer = 0
	collision_mask = 0
	monitoring = true
	base_y = position.y
	add_to_group("item_pickup")

func _process(delta: float):
	if collected: return

	bob_timer += delta
	position.y = base_y + sin(bob_timer * bob_speed) * bob_height

func collect() -> void:
	if collected or item_data == null: return
	collected = true

	ResourceManager.add_item(item_data, amount)

	# 浮动文字
	if FloatText:
		FloatText.show_float_text("+%d %s" % [amount, item_data.display_name], global_position, item_data.color)

	# 拾取动画：缩小并消失
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
