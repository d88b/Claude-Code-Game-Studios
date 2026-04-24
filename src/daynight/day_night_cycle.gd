extends Node
# DayNightCycle — 日夜循环控制器
## DayNightCycle — 日夜循环控制器
## 监听 time_phase_changed，应用视觉效果和危险倍率
## Core layer system (GDD day-night-cycle-system.md)

# === 阶段枚举 ===
enum Phase {
	DAWN,   ## 黎明 (05:00-07:00) — 危险等级×0.8
	DAY,    ## 白天 (07:00-18:00) — 危险等级×1.0
	DUSK,   ## 黄昏 (18:00-20:00) — 危险等级×1.2
	NIGHT   ## 夜晚 (20:00-05:00) — 危险等级×1.5
}

# === 常量定义 (来自 GDD) ===
## 过渡时长 (游戏秒) — 45 for smoother visual transitions (TK-007 updated)
const TRANSITION_DURATION: float = 45.0
## 全局危险倍率调优参数 (TK-006) — 1.1 from playtest feedback (10% increase)
const DANGER_GLOBAL_MULT: float = 1.1

# === 阶段危险基准倍率 ===
## 黎明危险倍率
const DAWN_DANGER_MULT: float = 0.8
## 白天危险倍率
const DAY_DANGER_MULT: float = 1.0
## 黄昏危险倍率
const DUSK_DANGER_MULT: float = 1.2
## 夜晚危险倍率
const NIGHT_DANGER_MULT: float = 1.5

# === 阶段视觉参数 ===
## 黎明环境光亮度 (0.6 → 0.9)
const DAWN_BRIGHTNESS_START: float = 0.6
const DAWN_BRIGHTNESS_END: float = 0.9
## 白天环境光亮度 (1.0)
const DAY_BRIGHTNESS: float = 1.0
## 黄昏环境光亮度 (0.9 → 0.5)
const DUSK_BRIGHTNESS_START: float = 0.9
const DUSK_BRIGHTNESS_END: float = 0.5
## 夜晚环境光亮度 (0.3)
const NIGHT_BRIGHTNESS: float = 0.3

# === 依赖引用 ===
## TimeSystem autoload 引用
var _time_system: Node = null
## GlobalSignals autoload 引用
var _global_signals: Node = null

# === 当前状态数据 ===
## 当前阶段
var current_phase: Phase = Phase.DAY
## 当前危险倍率
var current_danger_mult: float = DAY_DANGER_MULT * DANGER_GLOBAL_MULT
## 当前亮度
var current_brightness: float = DAY_BRIGHTNESS
## 过渡计时器
var transition_timer: float = 0.0
## 是否在过渡中
var is_transitioning: bool = false
## 过渡起始亮度
var transition_start_brightness: float = 0.0
## 过渡目标亮度
var transition_end_brightness: float = 0.0

# === 信号 ===
## 阶段效果已应用信号
signal phase_effects_applied(phase: Phase, danger_mult: float)

# === 依赖注入 API ===

func set_time_system(time: Node) -> void:
	_time_system = time

func set_global_signals(signals: Node) -> void:
	_global_signals = signals

func is_initialized() -> bool:
	return _global_signals != null

# === 查询 API ===

## 获取当前阶段
func get_current_phase() -> Phase:
	return current_phase

## 获取危险倍率
func get_danger_multiplier() -> float:
	return current_danger_mult

## 获取视觉参数
func get_visual_params() -> Dictionary:
	return {
		brightness = current_brightness,
		sky_color = _get_sky_color_for_phase(current_phase),
		fog_density = _get_fog_density_for_phase(current_phase)
	}

## 获取阶段剩余时间 (游戏秒)
func get_phase_time_remaining() -> float:
	if _time_system == null:
		return 0.0
	# stub — 需要 TimeSystem.get_phase_remaining_seconds()
	return 3600.0  # 默认 1 小时

## 获取阶段名称
func get_phase_name() -> String:
	match current_phase:
		Phase.DAWN: return "黎明"
		Phase.DAY: return "白天"
		Phase.DUSK: return "黄昏"
		Phase.NIGHT: return "夜晚"
		_: return "未知"

# === 内部方法 ===

## 获取阶段基准危险倍率
func _get_base_danger_mult(phase: Phase) -> float:
	match phase:
		Phase.DAWN: return DAWN_DANGER_MULT
		Phase.DAY: return DAY_DANGER_MULT
		Phase.DUSK: return DUSK_DANGER_MULT
		Phase.NIGHT: return NIGHT_DANGER_MULT
		_: return DAY_DANGER_MULT

## 获取阶段天空颜色
func _get_sky_color_for_phase(phase: Phase) -> Color:
	match phase:
		Phase.DAWN: return Color(0.9, 0.7, 0.5)  # 橙色
		Phase.DAY: return Color(0.6, 0.8, 1.0)  # 浅蓝
		Phase.DUSK: return Color(0.8, 0.4, 0.3)  # 橙红
		Phase.NIGHT: return Color(0.1, 0.15, 0.3)  # 深蓝黑
		_: return Color(0.6, 0.8, 1.0)

## 获取阶段雾密度
func _get_fog_density_for_phase(phase: Phase) -> float:
	match phase:
		Phase.DAWN: return 0.01
		Phase.DAY: return 0.005
		Phase.DUSK: return 0.02
		Phase.NIGHT: return 0.03
		_: return 0.005

## 获取阶段目标亮度
func _get_target_brightness(phase: Phase) -> float:
	match phase:
		Phase.DAWN: return DAWN_BRIGHTNESS_END
		Phase.DAY: return DAY_BRIGHTNESS
		Phase.DUSK: return DUSK_BRIGHTNESS_END
		Phase.NIGHT: return NIGHT_BRIGHTNESS
		_: return DAY_BRIGHTNESS

## 处理阶段变更
func _on_phase_changed(new_phase: int) -> void:
	# 转换阶段类型
	var phase: Phase = new_phase as Phase

	# 如果与当前阶段相同，忽略
	if phase == current_phase:
		return

	# 开始过渡
	is_transitioning = true
	transition_timer = 0.0
	transition_start_brightness = current_brightness
	transition_end_brightness = _get_target_brightness(phase)

	# 更新阶段和危险倍率
	current_phase = phase
	current_danger_mult = _get_base_danger_mult(phase) * DANGER_GLOBAL_MULT

	# 发出效果应用信号
	phase_effects_applied.emit(phase, current_danger_mult)

	# 发出 GlobalSignals.day_phase_changed
	if _global_signals != null:
		_global_signals.day_phase_changed.emit(new_phase)

# === 每帧处理 ===

func _process(delta: float) -> void:
	# 处理视觉过渡
	if is_transitioning:
		transition_timer += delta

		if transition_timer >= TRANSITION_DURATION:
			# 过渡完成
			current_brightness = transition_end_brightness
			is_transitioning = false
		else:
			# 线性插值
			var progress: float = transition_timer / TRANSITION_DURATION
			current_brightness = transition_start_brightness + \
				(transition_end_brightness - transition_start_brightness) * progress

# === 手动设置阶段 (用于测试) ===

func set_phase_for_test(phase: Phase) -> void:
	current_phase = phase
	current_danger_mult = _get_base_danger_mult(phase) * DANGER_GLOBAL_MULT
	current_brightness = _get_target_brightness(phase)
	is_transitioning = false

# === 生命周期 ===

func _ready() -> void:
	_auto_find_dependencies()
	_connect_signals()
	print("[DayNightCycle] initialized — current_phase=", get_phase_name())

## 自动查找依赖
func _auto_find_dependencies() -> void:
	# 获取 TimeSystem autoload
	if _time_system == null:
		_time_system = get_node_or_null("/root/TimeSystem")

	# 获取 GlobalSignals autoload
	if _global_signals == null:
		_global_signals = get_node_or_null("/root/GlobalSignals")

## 连接信号
func _connect_signals() -> void:
	if _global_signals != null:
		_global_signals.day_phase_changed.connect(_on_phase_changed)