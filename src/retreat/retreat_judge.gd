# retreat_judge.gd
# RetreatJudge — 撤退判定系统
## RetreatJudge — 撤退阈值检测系统
## 监控战车生命值、魔能、时间阶段，触发撤退警告
## Feature layer system (GDD retreat-judgment-system.md, ADR-004, ADR-005, ADR-007)

class_name RetreatJudge extends Node

# === 常量定义 (来自 GDD) ===
## 生命值危险阈值 (20%)
const HEALTH_CRITICAL_THRESHOLD: float = 0.20
## 魔能耗尽阈值 (10%)
const MAGIC_DEPLETED_THRESHOLD: float = 0.10
## 状态检查间隔 (秒) — 避免每帧检查
const CHECK_INTERVAL: float = 0.5

# === 撤退原因枚举 ===
enum RetreatReason {
	NONE,           ## 无撤退警告
	HEALTH_CRITICAL,## 生命值危险 (< 20%)
	MAGIC_DEPLETED,  ## 魔能耗尽 (< 10%)
	NIGHT_FALL,      ## 夜晚降临
	MULTIPLE         ## 多重危险叠加
}

# === 信号 ===
## 撤退警告触发 (reason: int)
signal retreat_warning_triggered(reason: int)
## 撤退警告解除
signal retreat_warning_resolved()

# === 状态变量 ===
## 当前撤退状态
var current_retreat_state: RetreatReason = RetreatReason.NONE
## 上次检查时间
var _check_timer: float = 0.0
## 是否处于警告状态
var _is_warning_active: bool = false
## 触发警告的原因列表
var _active_reasons: Array[int] = []

# === 依赖引用 ===
var _vehicle_attribute: Object = null
var _time_system: Object = null
var _global_signals: Object = null

# === 初始化 ===

func _ready() -> void:
	_auto_find_dependencies()

func _process(delta: float) -> void:
	# 使用定时检查，避免每帧检查
	_check_timer += delta
	if _check_timer < CHECK_INTERVAL:
		return
	_check_timer = 0.0

	_check_retreat_conditions()

## 自动查找依赖节点
func _auto_find_dependencies() -> void:
	if _vehicle_attribute == null:
		_vehicle_attribute = get_node_or_null("/root/VehicleAttribute")
	if _time_system == null:
		_time_system = get_node_or_null("/root/TimeSystem")
	if _global_signals == null:
		_global_signals = get_node_or_null("/root/GlobalSignals")

## 设置依赖注入 (用于测试)
func set_dependencies(vehicle_attribute: Object, time_system: Object,
		global_signals: Object) -> void:
	_vehicle_attribute = vehicle_attribute
	_time_system = time_system
	_global_signals = global_signals

# === 撤退条件检查 ===

func _check_retreat_conditions() -> void:
	# 检查所有可能触发撤退的条件
	var reasons: Array[int] = []

	# 检查生命值
	if _check_health_critical():
		reasons.append(RetreatReason.HEALTH_CRITICAL)

	# 检查魔能
	if _check_magic_depleted():
		reasons.append(RetreatReason.MAGIC_DEPLETED)

	# 检查夜晚降临
	if _check_night_fall():
		reasons.append(RetreatReason.NIGHT_FALL)

	# 处理状态变化
	_handle_state_change(reasons)

## 检查生命值危险阈值
func _check_health_critical() -> bool:
	if _vehicle_attribute == null:
		return false

	var health_ratio: float = _vehicle_attribute.get_durability_ratio()
	return health_ratio < HEALTH_CRITICAL_THRESHOLD

## 检查魔能耗尽阈值
func _check_magic_depleted() -> bool:
	if _vehicle_attribute == null:
		return false

	var magic_ratio: float = _vehicle_attribute.get_magic_energy_ratio()
	return magic_ratio < MAGIC_DEPLETED_THRESHOLD

## 检查夜晚降临
func _check_night_fall() -> bool:
	if _time_system == null:
		return false

	# TimeSystem.DayPhase.NIGHT = 3
	var phase: int = _time_system.get_phase()
	return phase == 3  # NIGHT phase

## 处理状态变化
func _handle_state_change(reasons: Array[int]) -> void:
	var was_warning_active: bool = _is_warning_active
	var old_reasons: Array[int] = _active_reasons.duplicate()

	# 更新当前状态
	_active_reasons = reasons
	_is_warning_active = reasons.size() > 0

	# 确定主要撤退原因
	var primary_reason: RetreatReason = _determine_primary_reason(reasons)

	# 检查是否有状态变化
	if _is_warning_active != was_warning_active:
		if _is_warning_active:
			# 新触发警告
			_trigger_warning(primary_reason)
		else:
			# 警告解除
			_clear_warning()
	elif _is_warning_active and primary_reason != current_retreat_state:
		# 警告原因变化（升级或降级）
		_update_warning(primary_reason)

## 确定主要撤退原因
func _determine_primary_reason(reasons: Array[int]) -> RetreatReason:
	if reasons.size() == 0:
		return RetreatReason.NONE
	elif reasons.size() == 1:
		return reasons[0]
	else:
		# 多重危险叠加
		return RetreatReason.MULTIPLE

## 触发撤退警告
func _trigger_warning(reason: RetreatReason) -> void:
	current_retreat_state = reason

	# 发射局部信号
	emit_signal("retreat_warning_triggered", reason)

	# 发射全局信号
	if _global_signals != null:
		var reason_str: String = _get_reason_string(reason)
		_global_signals.retreat_threshold_reached.emit(reason_str)

	print("[RetreatJudge] Retreat warning triggered: %s" % [_get_reason_string(reason)])

## 解除撤退警告
func _clear_warning() -> void:
	current_retreat_state = RetreatReason.NONE

	# 发射局部信号
	emit_signal("retreat_warning_resolved")

	# 发射全局信号
	if _global_signals != null:
		_global_signals.retreat_warning_cleared.emit()

	print("[RetreatJudge] Retreat warning cleared — conditions normalized")

## 更新撤退警告 (原因变化)
func _update_warning(reason: RetreatReason) -> void:
	current_retreat_state = reason

	# 发射局部信号
	emit_signal("retreat_warning_triggered", reason)

	# 发射全局信号 (更新警告)
	if _global_signals != null:
		var reason_str: String = _get_reason_string(reason)
		_global_signals.retreat_threshold_reached.emit(reason_str)

	print("[RetreatJudge] Retreat warning updated: %s" % [_get_reason_string(reason)])

## 获取原因字符串
func _get_reason_string(reason: RetreatReason) -> String:
	match reason:
		RetreatReason.HEALTH_CRITICAL:
			return "health_critical"
		RetreatReason.MAGIC_DEPLETED:
			return "magic_depleted"
		RetreatReason.NIGHT_FALL:
			return "night_fall"
		RetreatReason.MULTIPLE:
			return "multiple_dangers"
		_:
			return "unknown"

# === 公共 API ===

## 获取当前撤退状态
func get_retreat_state() -> RetreatReason:
	return current_retreat_state

## 检查是否处于警告状态
func is_warning_active() -> bool:
	return _is_warning_active

## 获取活跃警告原因列表
func get_active_reasons() -> Array[int]:
	return _active_reasons.duplicate()

## 获取活跃原因数量
func get_danger_count() -> int:
	return _active_reasons.size()

## 强制触发警告 (用于测试)
func force_trigger_warning(reason: RetreatReason) -> void:
	_trigger_warning(reason)

## 强制清除警告 (用于测试)
func force_clear_warning() -> void:
	_is_warning_active = false
	_active_reasons = []
	_clear_warning()

# === 测试辅助方法 ===

## 设置检查计时器 (用于测试)
func set_check_timer_for_test(value: float) -> void:
	_check_timer = value

## 设置警告状态 (用于测试)
func set_warning_state_for_test(active: bool, reasons: Array[int]) -> void:
	_is_warning_active = active
	_active_reasons = reasons

## 设置撤退状态 (用于测试)
func set_retreat_state_for_test(reason: RetreatReason) -> void:
	current_retreat_state = reason

# === 生命周期 ===

func _exit_tree() -> void:
	# 清理状态
	_is_warning_active = false
	_active_reasons = []
	current_retreat_state = RetreatReason.NONE