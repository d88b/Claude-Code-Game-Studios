# vehicle_controller.gd
# VehicleController - 战车移动核心循环
## VehicleController — 战车移动核心循环
## 实现战车的输入处理、加速度、速度限制、碰撞响应和魔能消耗
## Core layer system (ADR-008, TR-driving-001/002/003)

class_name VehicleController extends Node2D

# === 信号 ===
## 速度变化 (new_velocity: Vector2)
signal velocity_changed(new_velocity: Vector2)
## 朝向变化 (new_angle: float)
signal orientation_changed(new_angle: float)
## 碰撞检测 (cell: Vector2i, severity: float)
signal collision_detected(cell: Vector2i, severity: float)

# === 常量 ===
## 单元格尺寸 (像素) — 与 TileMapWorld 同步
const CELL_SIZE: int = 32
## 魔能消耗率 (每单元格) — TK-013
const MAGIC_COST_PER_CELL: float = 0.5
## 基础加速度 (单元格/秒²) — 默认值，从 VehicleTypeDB 覆盖
const ACCELERATION_BASE: float = 2.0
## 自然减速系数
const DRAG_COEFFICIENT: float = 1.0
## 碰撞体宽度 (单元格)
const BODY_WIDTH_CELLS: int = 2
## 碰撞体高度 (单元格)
const BODY_HEIGHT_CELLS: int = 2

# === 状态变量 ===
## 当前速度向量 (像素/秒)
var velocity: Vector2 = Vector2.ZERO
## 当前速度标量 (像素/秒)
var current_speed: float = 0.0
## 最大速度 (像素/秒) — 从 VehicleTypeDB 加载
var max_speed: float = 200.0
## 加速度 (像素/秒²) — 从 VehicleTypeDB 加载
var acceleration_rate: float = 500.0
## 战车类型 ID
var vehicle_id: int = 1

# === 依赖引用 ===
var _input_manager: Node = null
var _collision_manager: Node = null
var _vehicle_attribute: Node = null
var _vehicle_type_db: Node = null
var _global_signals: Node = null

# === 初始化 ===

func _ready() -> void:
	print("[VehicleController] ========== _ready() START ==========")
	print("[VehicleController] script loaded, vehicle_id: ", vehicle_id)
	print("[VehicleController] node name: ", name)
	print("[VehicleController] node path: ", get_path())

	_auto_find_dependencies()
	_load_vehicle_stats()

	# 调试输出
	if _input_manager == null:
		push_error("[VehicleController] InputManager NOT FOUND!")
	else:
		print("[VehicleController] InputManager found: ", _input_manager)

	if _collision_manager == null:
		push_warning("[VehicleController] CollisionManager not found")
	else:
		print("[VehicleController] CollisionManager found")

	if _vehicle_attribute == null:
		push_warning("[VehicleController] VehicleAttribute not found")
	else:
		print("[VehicleController] VehicleAttribute found")

	print("[VehicleController] Ready — vehicle_id=%d, max_speed=%.1f, accel=%.1f" % [vehicle_id, max_speed, acceleration_rate])
	print("[VehicleController] ========== _ready() END ==========")

	# 启用物理处理
	set_physics_process(true)

## 自动查找场景中的依赖节点
func _auto_find_dependencies() -> void:
	# 获取 InputManager autoload
	if _input_manager == null:
		_input_manager = get_node_or_null("/root/InputManager")

	# 获取 CollisionManager autoload
	if _collision_manager == null:
		_collision_manager = get_node_or_null("/root/CollisionManager")

	# 获取 VehicleTypeDB autoload
	if _vehicle_type_db == null:
		_vehicle_type_db = get_node_or_null("/root/VehicleTypeDB")

	# 获取 GlobalSignals autoload
	if _global_signals == null:
		_global_signals = get_node_or_null("/root/GlobalSignals")

	# 查找同节点的 VehicleAttribute 组件
	if _vehicle_attribute == null:
		_vehicle_attribute = get_node_or_null("VehicleAttribute")
		if _vehicle_attribute == null:
			# 尝试从父节点或子节点查找
			for child in get_children():
				if child is VehicleAttribute:
					_vehicle_attribute = child
					break

## 从 VehicleTypeDB 加载战车属性
func _load_vehicle_stats() -> void:
	if _vehicle_type_db == null:
		push_warning("[VehicleController] VehicleTypeDB not found, using defaults")
		return

	var stats: Object = _vehicle_type_db.get_vehicle_stats(vehicle_id)
	if stats == null:
		push_warning("[VehicleController] Invalid vehicle_id=%d, using defaults" % vehicle_id)
		return

	max_speed = stats.max_speed
	acceleration_rate = stats.acceleration_rate
	print("[VehicleController] Loaded stats for vehicle_id=%d" % vehicle_id)

## 设置依赖注入 (用于测试)
func set_dependencies(input_manager: Node, collision_manager: Node,
		vehicle_attribute: Node, vehicle_type_db: Node, global_signals: Node) -> void:
	_input_manager = input_manager
	_collision_manager = collision_manager
	_vehicle_attribute = vehicle_attribute
	_vehicle_type_db = vehicle_type_db
	_global_signals = global_signals

## 设置战车 ID (初始化时调用)
func initialize(p_vehicle_id: int) -> void:
	vehicle_id = p_vehicle_id
	_load_vehicle_stats()

# === 主循环 ===

func _physics_process(delta: float) -> void:
	# 1. 读取输入
	var input_dir: Vector2 = _read_input()

	# 调试输出（有输入时，仅调试构建）
	if input_dir.length() > 0.1 and OS.is_debug_build():
		print("[VehicleController] input_dir: ", input_dir, " velocity: ", velocity)

	# 2. 计算加速度
	_apply_acceleration(input_dir, delta)

	# 3. 速度限制
	_clamp_speed()

	# 4. 碰撞检测
	var collision_result: Dictionary = _check_collision(delta)

	# 5. 碰撞响应
	if collision_result.hit:
		_handle_collision(collision_result)

	# 6. 魔能消耗
	var magic_consumed: float = _consume_magic_for_movement(delta)

	# 7. 应用移动
	_apply_movement(delta)

	# 8. 发射事件
	_emit_events()

# === 内部方法 ===

## 读取输入方向 (TR-driving-001)
func _read_input() -> Vector2:
	if _input_manager == null:
		return Vector2.ZERO

	return _input_manager.get_joystick_direction()

## 应用加速度 (TR-driving-001)
## 公式: velocity += acceleration_rate * input_direction * delta
func _apply_acceleration(input_dir: Vector2, delta: float) -> void:
	if input_dir.length() > 0.01:
		# 有输入: 加速
		velocity += acceleration_rate * input_dir * delta
	else:
		# 无输入: 自然减速
		velocity *= 1.0 - DRAG_COEFFICIENT * delta

## 速度限制 (TR-driving-002)
## 公式: |velocity| <= max_speed
func _clamp_speed() -> void:
	velocity = velocity.limit_length(max_speed)
	current_speed = velocity.length()

## 碰撞检测 (ADR-008)
func _check_collision(delta: float) -> Dictionary:
	if _collision_manager == null:
		return {"hit": false}

	var bounds: Rect2 = get_vehicle_bounds()
	var motion: Vector2 = velocity * delta

	var result: Object = _collision_manager.check_swept_collision(bounds, motion)
	if result == null:
		return {"hit": false}

	return {
		"hit": result.hit,
		"hit_cell": result.hit_cell,
		"severity": result.severity,
		"remaining_velocity": result.remaining_velocity,
		"hit_position": result.hit_position
	}

## 碰撞响应 — 弹跳因子 0.5
func _handle_collision(collision_result: Dictionary) -> void:
	# 弹跳因子: 速度减半
	velocity = collision_result.remaining_velocity * 0.5

	# 发射碰撞信号
	var hit_cell: Vector2i = collision_result.get("hit_cell", Vector2i.ZERO)
	var severity: float = collision_result.get("severity", 0.0)
	collision_detected.emit(hit_cell, severity)

	# 发射全局信号
	if _global_signals != null:
		_global_signals.vehicle_damaged.emit(severity * 10.0)  # 碰撞伤害

## 魔能消耗 (TR-driving-003)
## 公式: cells_moved * MAGIC_COST_PER_CELL
func _consume_magic_for_movement(delta: float) -> float:
	if _vehicle_attribute == null:
		return 0.0

	var cells_moved: float = velocity.length() * delta / float(CELL_SIZE)

	if cells_moved < 0.01:
		return 0.0

	var magic_cost: float = cells_moved * MAGIC_COST_PER_CELL

	if not _vehicle_attribute.consume_magic(magic_cost):
		# 魔能耗尽 → 减速
		velocity *= 0.5
		return 0.0

	return magic_cost

## 应用移动
func _apply_movement(delta: float) -> void:
	position += velocity * delta

## 发射事件
func _emit_events() -> void:
	velocity_changed.emit(velocity)

	var angle: float = velocity.angle()
	orientation_changed.emit(angle)

	# 全局信号
	if _global_signals != null:
		# 使用自定义信号，不使用 velocity_changed (GlobalSignals 没有)
		pass

# === 公共 API ===

## 获取战车碰撞体边界 (世界坐标)
func get_vehicle_bounds() -> Rect2:
	var half_width: float = float(BODY_WIDTH_CELLS * CELL_SIZE) / 2.0
	var half_height: float = float(BODY_HEIGHT_CELLS * CELL_SIZE) / 2.0

	return Rect2(
		position.x - half_width,
		position.y - half_height,
		float(BODY_WIDTH_CELLS * CELL_SIZE),
		float(BODY_HEIGHT_CELLS * CELL_SIZE)
	)

## 获取当前速度向量
func get_current_velocity() -> Vector2:
	return velocity

## 获取当前速度标量
func get_current_speed() -> float:
	return current_speed

## 获取朝向角度 (弧度)
func get_orientation() -> float:
	return velocity.angle()

## 设置速度 (用于测试)
func set_velocity_for_test(new_velocity: Vector2) -> void:
	velocity = new_velocity
	current_speed = velocity.length()

## 强制停止
func stop() -> void:
	velocity = Vector2.ZERO
	current_speed = 0.0