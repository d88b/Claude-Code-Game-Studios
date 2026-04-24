extends Node
# InputManager — 输入管理器 (Autoload)
## InputManager — 输入管理器
## 处理双焦点输入系统 (KB/gamepad vs mouse/touch)
## Foundation layer system (ADR-003) — HIGH RISK: 需在 Godot 4.6 上验证

# === 焦点模式枚举 ===
enum FocusMode { KEYBOARD_GAMEPAD, MOUSE_TOUCH, BOTH }

# === 状态变量 ===
## 当前焦点模式
var current_focus: FocusMode = FocusMode.KEYBOARD_GAMEPAD
## 动作状态快照：{action_name: bool}
var action_map: Dictionary = {}
## 鼠标世界位置
var mouse_position: Vector2 = Vector2.ZERO
## 手柄方向向量
var joystick_direction: Vector2 = Vector2.ZERO

# === 常量定义 ===
## 监听的动作列表
const TRACKED_ACTIONS: Array[String] = [
	"move_up", "move_down", "move_left", "move_right",
	"fire", "dig", "place", "menu_toggle", "pause"
]
## 手柄死区阈值
const JOYSTICK_DEAD_ZONE: float = 0.2

# === 查询 API ===

## 检查动作是否按下
func is_action_pressed(action: String) -> bool:
	return action_map.get(action, false)

## 检查动作是否刚按下 (当前帧)
func is_action_just_pressed(action: String) -> bool:
	return Input.is_action_just_pressed(action)

## 检查动作是否刚释放 (当前帧)
func is_action_just_released(action: String) -> bool:
	return Input.is_action_just_released(action)

## 获取鼠标世界位置
func get_mouse_position() -> Vector2:
	return mouse_position

## 获取手柄方向向量
func get_joystick_direction() -> Vector2:
	return joystick_direction

## 获取当前焦点模式
func get_focus_mode() -> FocusMode:
	return current_focus

# === 内部更新 ===

func _update_action_map() -> void:
	# 更新动作状态快照
	for action: String in TRACKED_ACTIONS:
		action_map[action] = Input.is_action_pressed(action)

func _update_mouse_position() -> void:
	# 获取鼠标视口位置
	var viewport_pos: Vector2 = get_viewport().get_mouse_position()
	# 转换为世界坐标 (假设有相机)
	mouse_position = viewport_pos

func _update_joystick_direction() -> void:
	# 获取手柄输入
	var x: float = Input.get_axis("move_left", "move_right")
	var y: float = Input.get_axis("move_up", "move_down")
	# 应用死区
	if absf(x) < JOYSTICK_DEAD_ZONE:
		x = 0.0
	if absf(y) < JOYSTICK_DEAD_ZONE:
		y = 0.0
	joystick_direction = Vector2(x, y).normalized()

func _update_focus_mode() -> void:
	# ⚠️ HIGH RISK: Dual-focus 是 Godot 4.6 新特性
	# 检测键盘/手柄输入
	var kb_gamepad_active: bool = false
	for action: String in ["move_up", "move_down", "move_left", "move_right"]:
		if Input.is_action_pressed(action):
			kb_gamepad_active = true
			break

	# 检测鼠标输入
	var mouse_active: bool = Input.get_last_mouse_velocity().length() > 0.0

	# 更新焦点模式
	if kb_gamepad_active and mouse_active:
		current_focus = FocusMode.BOTH
	elif kb_gamepad_active:
		current_focus = FocusMode.KEYBOARD_GAMEPAD
	elif mouse_active:
		current_focus = FocusMode.MOUSE_TOUCH
	# 默认保持当前焦点

# === 生命周期 ===

func _ready() -> void:
	# 初始化动作快照
	for action: String in TRACKED_ACTIONS:
		action_map[action] = false
	print("[InputManager] initialized — HIGH RISK: verify dual-focus on Godot 4.6")

func _process(delta: float) -> void:
	_update_action_map()
	_update_mouse_position()
	_update_joystick_direction()
	_update_focus_mode()