# test_movement_direct.gd
# 简化战车控制器 — Vertical Slice MVP（无碰撞限制版本）
extends Node2D

# === 配置 ===
## 移动速度 (像素/秒)
var move_speed: float = 400.0
## 魔能消耗率 (每秒)
var magic_drain_rate: float = 2.0

# === 状态 ===
var velocity: Vector2 = Vector2.ZERO

# === 依赖 ===
var _vehicle_attribute: Node = null
var _global_signals: Node = null

func _ready() -> void:
	# 查找依赖
	_vehicle_attribute = get_node_or_null("VehicleAttribute")
	_global_signals = GlobalSignals

	# 启用相机
	var camera: Camera2D = get_node_or_null("Camera2D")
	if camera != null:
		camera.enabled = true
		print("[Vehicle] Camera enabled")

	print("[Vehicle] Initialized — move_speed=", move_speed)
	print("[Vehicle] Position: ", position)

func _physics_process(delta: float) -> void:
	# 记录前一帧位置
	var prev_pos: Vector2 = position

	# 读取输入
	var input_dir: Vector2 = Vector2.ZERO

	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	# 标准化方向
	if input_dir.length() > 0.01:
		input_dir = input_dir.normalized()
		velocity = input_dir * move_speed

		# 消耗魔能
		if _vehicle_attribute != null:
			_vehicle_attribute.consume_magic(magic_drain_rate * delta)
	else:
		# 无输入时停止
		velocity = Vector2.ZERO

	# 计算新位置
	var new_pos: Vector2 = position + velocity * delta

	# 如果位置发生变化（且没有输入），说明有其他东西修改了它
	if prev_pos != new_pos and velocity.length() < 0.01:
		print("[Vehicle] POSITION CHANGED BY UNKNOWN SOURCE! prev=", prev_pos, " new=", new_pos)

	# 应用移动（无碰撞检测）
	position = new_pos

	# 如果按下方向键但位置没有变化，说明被阻挡
	if input_dir.length() > 0.01 and abs(prev_pos.x - position.x) < 0.1 and abs(prev_pos.y - position.y) < 0.1:
		print("[Vehicle] BLOCKED! input_dir=", input_dir, " velocity=", velocity, " pos=", position)