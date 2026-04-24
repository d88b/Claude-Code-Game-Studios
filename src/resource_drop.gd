# resource_drop.gd
# 资源掉落物 — 战车接触后自动收集
extends Area2D

# === 资源类型 ===
var resource_type: int = 0  # 资源ID
var quantity: float = 10.0  # 数量

# === 视觉 ===
var _body: Polygon2D = null
var _outline: Polygon2D = null
var _glow_timer: float = 0.0

# === 信号 ===
signal collected(resource_id: int, amount: float)

# === 预设资源颜色 ===
const RESOURCE_COLORS: Dictionary = {
	0: Color(0.3, 0.8, 0.3, 1),   # 木材 — 绿色
	1: Color(0.6, 0.6, 0.7, 1),   # 石头 — 灰色
	2: Color(0.8, 0.7, 0.3, 1),   # 铁矿 — 黄铜色
	3: Color(0.4, 0.7, 0.9, 1),   # 水晶 — 浅蓝
	4: Color(0.9, 0.3, 0.9, 1),   # 魔能碎片 — 粉紫
}

func _ready() -> void:
	# 创建视觉
	_create_visual()

	# 设置碰撞
	collision_layer = 8  # 资源层
	collision_mask = 1   # 检测玩家

	# 连接碰撞信号
	body_entered.connect(_on_body_entered)

	# 添加到资源组
	add_to_group("resources")

	print("[ResourceDrop] 资源掉落物初始化 — type=", resource_type, " qty=", quantity, " at ", position)

func _create_visual() -> void:
	# 获取资源颜色
	var color: Color = RESOURCE_COLORS.get(resource_type, Color(0.5, 0.5, 0.5, 1))

	# 外框（发光效果）
	_outline = Polygon2D.new()
	_outline.color = color.lerp(Color(1, 1, 1, 1), 0.5)
	_outline.polygon = PackedVector2Array([Vector2(-20, -20), Vector2(20, -20), Vector2(20, 20), Vector2(-20, 20)])
	_outline.z_index = 5
	add_child(_outline)

	# 内部
	_body = Polygon2D.new()
	_body.color = color
	_body.polygon = PackedVector2Array([Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16)])
	_body.z_index = 6
	add_child(_body)

func _process(delta: float) -> void:
	# 闪烁发光效果
	_glow_timer += delta
	if _outline != null:
		var glow: float = 0.3 + 0.2 * sin(_glow_timer * 3.0)
		_outline.color = _outline.color.lerp(_body.color, glow)

func _on_body_entered(body: Node2D) -> void:
	# 检查是否是战车
	if body.is_in_group("vehicles") or body.name == "PhysicsVehicle":
		# 发送收集信号
		emit_signal("collected", resource_type, quantity)

		# 发送全局信号
		var global_signals: Node = GlobalSignals
		if global_signals != null:
			global_signals.resource_collected.emit(resource_type, quantity)

		print("[ResourceDrop] 收集资源 — type=", resource_type, " qty=", quantity)

		# 消除掉落物
		queue_free()

## 设置资源类型和数量
func set_resource(type: int, qty: float) -> void:
	resource_type = type
	quantity = qty

	# 更新颜色
	if _body != null:
		_body.color = RESOURCE_COLORS.get(type, Color(0.5, 0.5, 0.5, 1))