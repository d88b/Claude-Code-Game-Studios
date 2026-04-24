# daynight_visual.gd
# 日夜视觉效果 — 全屏颜色层
extends CanvasLayer

# === 阶段颜色（增加透明度让效果更明显）===
const COLOR_DAWN: Color = Color(0.9, 0.6, 0.4, 0.25)   # 黎明 — 橙色
const COLOR_DAY: Color = Color(1.0, 1.0, 1.0, 0.0)    # 白天 — 无覆盖
const COLOR_DUSK: Color = Color(0.9, 0.4, 0.2, 0.35)  # 黄昏 — 橙红
const COLOR_NIGHT: Color = Color(0.2, 0.2, 0.4, 0.5)  # 夜晚 — 深蓝黑

# === 节点引用 ===
var _color_rect: ColorRect = null
var _daynight_cycle: Node = null
var _global_signals: Node = null

# === 当前状态 ===
var _current_phase: int = 1  # 默认白天
var _target_color: Color = COLOR_DAY
var _start_color: Color = COLOR_DAY
var _transition_duration: float = 2.0  # 过渡时长（秒）
var _transition_timer: float = 0.0
var _is_transitioning: bool = false

func _ready() -> void:
	_global_signals = GlobalSignals

	# 创建全屏颜色层
	_create_visual_layer()

	# 连接信号
	_connect_signals()

	# 尝试获取 DayNightCycle
	_daynight_cycle = get_node_or_null("../DayNightCycle")
	if _daynight_cycle == null:
		_daynight_cycle = get_tree().current_scene.get_node_or_null("DayNightCycle")

	print("[DayNightVisual] 视觉层初始化完成")

func _create_visual_layer() -> void:
	_color_rect = ColorRect.new()
	_color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_color_rect.color = COLOR_DAY
	# 不设置 z_index，由 CanvasLayer 的 layer 控制渲染顺序
	add_child(_color_rect)

func _connect_signals() -> void:
	if _global_signals != null:
		_global_signals.day_phase_changed.connect(_on_phase_changed)

func _process(delta: float) -> void:
	if _is_transitioning and _color_rect != null:
		_transition_timer += delta

		if _transition_timer >= _transition_duration:
			_color_rect.color = _target_color
			_is_transitioning = false
		else:
			var progress: float = _transition_timer / _transition_duration
			# 使用平滑插值
			_color_rect.color = _start_color.lerp(_target_color, progress)

func _on_phase_changed(phase: int) -> void:
	_current_phase = phase

	# 保存当前颜色作为起始颜色
	if _color_rect != null:
		_start_color = _color_rect.color

	# 获取目标颜色
	match phase:
		0: _target_color = COLOR_DAWN   # DAWN
		1: _target_color = COLOR_DAY    # DAY
		2: _target_color = COLOR_DUSK   # DUSK
		3: _target_color = COLOR_NIGHT  # NIGHT

	# 开始过渡
	_is_transitioning = true
	_transition_timer = 0.0

	print("[DayNightVisual] 阶段变化: ", _get_phase_name(phase), " 目标颜色: ", _target_color)

func _get_phase_name(phase: int) -> String:
	match phase:
		0: return "黎明"
		1: return "白天"
		2: return "黄昏"
		3: return "夜晚"
		_: return "未知"

# === 测试用：手动切换阶段 ===
func force_phase(phase: int) -> void:
	_on_phase_changed(phase)