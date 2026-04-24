# day_night_visual.gd
# DayNightVisual — 日夜视觉调制器
## DayNightVisual — 日夜循环视觉表现
## 监听 GlobalSignals.day_phase_changed，更新 CanvasModulate 颜色

extends CanvasModulate

# === 预定义颜色 ===
## 黎明颜色 (暖橙色)
const DAWN_COLOR: Color = Color(0.95, 0.85, 0.7, 1.0)
## 白天颜色 (正常)
const DAY_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
## 黄昏颜色 (橙红)
const DUSK_COLOR: Color = Color(0.85, 0.6, 0.4, 1.0)
## 夜晚颜色 (深蓝暗)
const NIGHT_COLOR: Color = Color(0.3, 0.35, 0.5, 1.0)

# === 依赖 ===
var _global_signals: Node = null

# === 初始化 ===

func _ready() -> void:
	_global_signals = GlobalSignals

	# 连接信号
	if _global_signals != null:
		_global_signals.day_phase_changed.connect(_on_phase_changed)

	# 初始颜色 (白天)
	color = DAY_COLOR

	print("[DayNightVisual] Initialized")

func _exit_tree() -> void:
	# 断开信号
	if _global_signals != null:
		if _global_signals.day_phase_changed.is_connected(_on_phase_changed):
			_global_signals.day_phase_changed.disconnect(_on_phase_changed)

# === 信号回调 ===

func _on_phase_changed(phase: int) -> void:
	# 阶段映射: 0=DAWN, 1=DAY, 2=DUSK, 3=NIGHT
	match phase:
		0: color = DAWN_COLOR
		1: color = DAY_COLOR
		2: color = DUSK_COLOR
		3: color = NIGHT_COLOR
		_: color = DAY_COLOR

	print("[DayNightVisual] Phase changed to %d, color updated" % phase)