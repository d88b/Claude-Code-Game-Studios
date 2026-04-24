# physics_vehicle.gd
# 物理战车控制器 — 使用 CharacterBody2D 实现碰撞阻挡
extends CharacterBody2D

var move_speed: float = 400.0
var _speed_modifier: float = 1.0

# === Camera bounds ===
const CAM_LEFT: float = 0
const CAM_RIGHT: float = 1280
const CAM_TOP: float = 0
const CAM_BOTTOM: float = 720

# === 日夜测试 ===
var _test_phase: int = 1  # 默认白天
var _global_signals: Node = null

func _ready() -> void:
	# 添加到战车组
	add_to_group("vehicles")

	print("[PhysicsVehicle] Ready — move_speed=", move_speed)

	# 获取全局信号
	_global_signals = GlobalSignals

	# 设置相机限制
	var camera: Camera2D = get_node_or_null("Camera2D")
	if camera != null:
		camera.limit_left = CAM_LEFT
		camera.limit_right = CAM_RIGHT
		camera.limit_top = CAM_TOP
		camera.limit_bottom = CAM_BOTTOM

	# 连接减速区域检测
	var slow_zone: Area2D = get_node_or_null("SlowZoneDetector")
	if slow_zone != null:
		slow_zone.area_entered.connect(_on_slow_zone_entered)
		slow_zone.area_exited.connect(_on_slow_zone_exited)

func _unhandled_input(event: InputEvent) -> void:
	# 测试按键：T 键切换日夜阶段
	if event is InputEventKey and event.keycode == KEY_T and event.pressed and not event.is_echo():
		_test_phase = (_test_phase + 1) % 4  # 0→1→2→3→0
		if _global_signals != null:
			_global_signals.day_phase_changed.emit(_test_phase)
		var phase_names: Array = ["黎明", "白天", "黄昏", "夜晚"]
		print("[Test] 日夜阶段切换: ", phase_names[_test_phase])
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	var input_dir: Vector2 = Vector2.ZERO

	# 使用 WASD + 方向键
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1

	if input_dir.length() > 0.01:
		input_dir = input_dir.normalized()

	# 计算速度（应用减速修正）
	var target_velocity: Vector2 = input_dir * move_speed * _speed_modifier
	velocity = target_velocity

	# 使用 move_and_slide 处理物理碰撞
	move_and_slide()

	# 边界限制（如果没有碰撞阻挡则手动限制）
	position.x = clamp(position.x, CAM_LEFT + 32, CAM_RIGHT - 32)
	position.y = clamp(position.y, CAM_TOP + 32, CAM_BOTTOM - 32)

# === 减速区域检测 ===

func enter_slow_zone() -> void:
	_speed_modifier = 0.3
	print("[Vehicle] 进入减速区域 — 速度降低到30%")

func exit_slow_zone() -> void:
	_speed_modifier = 1.0
	print("[Vehicle] 退出减速区域 — 恢复正常速度")

func _on_slow_zone_entered(area: Area2D) -> void:
	if area.is_in_group("slow_zones"):
		enter_slow_zone()

func _on_slow_zone_exited(area: Area2D) -> void:
	if area.is_in_group("slow_zones"):
		exit_slow_zone()