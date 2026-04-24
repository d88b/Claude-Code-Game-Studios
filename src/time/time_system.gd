extends Node
# TimeSystem — 游戏时间系统 (Autoload)
## TimeSystem — 游戏时间系统
## 管理游戏时钟、时间尺度、日夜计数
## Foundation layer system — 所有时间驱动系统的同步源

# === 常量定义 (来自 entities.yaml TK-IDs) ===
## 时间尺度：1 实际秒 = 60 游戏秒
const TIME_SCALE_DEFAULT: float = 60.0
## 一天周期长度：10 分钟实际时间 = 24 游戏小时
const DAY_DURATION_SECONDS: float = 600.0
## 一小时的游戏秒数
const HOUR_SECONDS: float = 3600.0
## 一天的游戏秒数
const DAY_SECONDS: float = 86400.0

# === 日夜阶段边界 (游戏小时) ===
## 黎明开始时间 (5:00)
const DAWN_HOUR: int = 5
## 白天开始时间 (7:00)
const DAY_HOUR: int = 7
## 黄昏开始时间 (17:00)
const DUSK_HOUR: int = 17
## 夜晚开始时间 (19:00)
const NIGHT_HOUR: int = 19

# === 日夜阶段枚举 ===
enum DayPhase { DAWN, DAY, DUSK, NIGHT }

# === 状态变量 ===
## 当前游戏时间 (游戏秒)
var current_time: float = 0.0
## 天数计数
var day_count: int = 0
## 时间尺度倍率
var time_scale: float = TIME_SCALE_DEFAULT
## 当前日夜阶段
var _current_phase: DayPhase = DayPhase.NIGHT
## 上一次的小时数 (用于检测小时变化)
var _last_hour: int = -1

# === 信号 ===
## 小时变化信号 (hour: int)
signal time_hour_changed(hour: int)
## 日夜阶段变化信号 (phase: DayPhase)
signal day_phase_changed(phase: DayPhase)
## 天数变化信号 (day: int)
signal day_count_changed(day: int)

# === 查询 API ===

## 获取当前游戏小时 (0-23)
func get_current_hour() -> int:
	var total_hours: float = current_time / HOUR_SECONDS
	return int(total_hours) % 24

## 获取当前日夜阶段
func get_phase() -> DayPhase:
	return _current_phase

## 获取当前游戏秒
func get_current_time() -> float:
	return current_time

## 获取天数
func get_day_count() -> int:
	return day_count

## 获取时间尺度
func get_time_scale() -> float:
	return time_scale

## 设置时间尺度
func set_time_scale(new_scale: float) -> void:
	time_scale = new_scale

# === 阶段计算 ===

func _calculate_phase(hour: int) -> DayPhase:
	if hour < DAWN_HOUR:
		return DayPhase.NIGHT
	elif hour < DAY_HOUR:
		return DayPhase.DAWN
	elif hour < DUSK_HOUR:
		return DayPhase.DAY
	elif hour < NIGHT_HOUR:
		return DayPhase.DUSK
	else:
		return DayPhase.NIGHT

# === 危险倍率查询 ===

## 获取当前危险倍率 (夜晚更高)
## 黎明/白天/黄昏: 1.0, 夜晚: 2.0
func get_danger_multiplier() -> float:
	if _current_phase == DayPhase.NIGHT:
		return 2.0
	return 1.0

# === 时间控制 ===

## 设置当前时间 (用于测试或调试)
func set_time(game_seconds: float) -> void:
	current_time = game_seconds
	_update_phase()

## 跳转到指定小时 (保留天数)
func jump_to_hour(hour: int) -> void:
	var current_day_base: float = day_count * DAY_SECONDS
	current_time = current_day_base + hour * HOUR_SECONDS
	_update_phase()

# === 内部更新 ===

func _update_phase() -> void:
	var hour: int = get_current_hour()
	var new_phase: DayPhase = _calculate_phase(hour)

	# 检测小时变化
	if hour != _last_hour:
		emit_signal("time_hour_changed", hour)
		_last_hour = hour

	# 检测阶段变化
	if new_phase != _current_phase:
		_current_phase = new_phase
		emit_signal("day_phase_changed", _current_phase)

	# 检测天数变化
	var new_day: int = int(current_time / DAY_SECONDS)
	if new_day != day_count:
		day_count = new_day
		emit_signal("day_count_changed", day_count)

# === 生命周期 ===

func _ready() -> void:
	# 初始化为第一天黎明 (模拟从白天开始)
	current_time = DAY_HOUR * HOUR_SECONDS  # 7:00 AM
	_update_phase()
	print("[TimeSystem] initialized: hour=", get_current_hour(), " phase=", DayPhase.keys()[_current_phase])

func _process(delta: float) -> void:
	# 更新游戏时间
	current_time += delta * time_scale
	_update_phase()