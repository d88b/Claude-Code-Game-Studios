# resource_drop.gd
# ResourceDrop — 资源掉落实体
## ResourceDrop — 资源掉落实体
## 方块被摧毁后生成，玩家靠近自动拾取

class_name ResourceDrop extends Area2D

# === 配置 ===
## 资源类型 ID
var resource_id: int = 1
## 资源数量
var quantity: float = 1.0
## 拾取半径 (像素)
const PICKUP_RADIUS: float = 64.0
## 生命周期 (秒) — TK-045
const LIFETIME: float = 30.0
## 视觉缩放
const VISUAL_SCALE: float = 0.5

# === 状态 ===
var _lifetime_timer: float = 0.0
var _is_collected: bool = false

# === 依赖 ===
var _global_signals: Node = null

# === 初始化 ===

func _ready() -> void:
	_global_signals = GlobalSignals

	# 设置碰撞
	collision_layer = 32  # COLLISION_DROP layer
	collision_mask = 8    # 检测实体层 (vehicle)

	# 创建碰撞形状
	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	var circle_shape: CircleShape2D = CircleShape2D.new()
	circle_shape.radius = PICKUP_RADIUS
	collision_shape.shape = circle_shape
	add_child(collision_shape)

	# 创建视觉占位符
	var visual: Polygon2D = Polygon2D.new()
	var size: float = 16.0 * VISUAL_SCALE
	visual.polygon = PackedVector2Array([
		Vector2(-size, -size),
		Vector2(size, -size),
		Vector2(size, size),
		Vector2(-size, size)
	])
	visual.color = _get_resource_color()
	visual.offset = Vector2(0, 0)
	add_child(visual)

	# 连接拾取检测
	body_entered.connect(_on_body_entered)

	print("[ResourceDrop] Spawned: resource_id=%d, quantity=%.1f" % [resource_id, quantity])

func _process(delta: float) -> void:
	if _is_collected:
		return

	# 生命周期计时
	_lifetime_timer += delta
	if _lifetime_timer >= LIFETIME:
		_expire()

	# 简单动画：上下浮动
	var visual_node: Node = get_child(1) if get_child_count() > 1 else null
	if visual_node != null and visual_node is Polygon2D:
		var float_offset: float = sin(_lifetime_timer * 2.0) * 4.0
		visual_node.offset.y = float_offset

# === 设置资源 ===

func set_resource(res_id: int, qty: float) -> void:
	resource_id = res_id
	quantity = qty

# === 拾取逻辑 ===

func _on_body_entered(body: Node2D) -> void:
	if _is_collected:
		return

	# 检查是否是战车实体 (通过名称或脚本路径判断)
	if body.name.contains("Vehicle") or body.get_script() != null and body.get_script().resource_path.contains("vehicle"):
		_collect()

func _collect() -> void:
	_is_collected = true

	# 发射全局信号
	if _global_signals != null:
		_global_signals.resource_collected.emit(resource_id, quantity)

	print("[ResourceDrop] Collected: resource_id=%d, quantity=%.1f" % [resource_id, quantity])

	# 移除实体
	queue_free()

func _expire() -> void:
	_is_collected = true

	print("[ResourceDrop] Expired after %.1f seconds" % _lifetime_timer)

	queue_free()

# === 视觉辅助 ===

func _get_resource_color() -> Color:
	# 根据资源类型返回不同颜色（占位符）
	# 实际应从 ResourceDB 获取资源信息
	match resource_id:
		1: return Color(0.8, 0.2, 0.8, 1)   # 魔力晶石 - 紫
		2: return Color(0.6, 0.6, 0.7, 1)   # 秘银 - 银灰
		3: return Color(0.9, 0.7, 0.1, 1)   # 奥术碎片 - 金
		4: return Color(0.6, 0.4, 0.2, 1)   # 铁矿石 - 棕
		_: return Color(0.5, 0.5, 0.5, 1)   # 默认 - 灰