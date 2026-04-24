# vehicle_attribute.gd
# VehicleAttribute - 战车属性状态管理
## VehicleAttribute — 战车属性状态管理
## 管理战车的生命值、魔能池、货物等运行时状态
## Core layer component (ADR-007)

class_name VehicleAttribute extends Node

# === 信号 ===
## 生命值变化 (current: float, max: float)
signal health_changed(current: float, max_health: float)
## 魔能变化 (current: float, max: float)
signal magic_changed(current: float, max_magic: float)
## 状态变化 (new_state: int — VehicleState enum value)
signal state_changed(new_state: int)

# === 常量 ===
## DISABLED 阈值：生命值比例 < 20%
const DISABLED_HEALTH_THRESHOLD: float = 0.20
## DESTROYED 阈值：生命值比例 <= 0
const DESTROYED_HEALTH_THRESHOLD: float = 0.0
## 魔能耗尽阈值：魔能比例 < 10% (TK-014)
const MAGIC_DEPLETION_THRESHOLD: float = 0.10

# === 属性 ===
## 当前生命值
var current_health: float = 0.0
## 最大生命值
var max_health: float = 100.0
## 当前魔能
var current_magic: float = 0.0
## 最大魔能
var max_magic: float = 100.0
## 战车类型 ID
var vehicle_id: int = 1
## 当前状态
var _current_state: int = VehicleTypeDB.VehicleState.DEPLOYED

# === 依赖注入 ===
var _vehicle_type_db: Object = null
var _global_signals: Object = null

# === 初始化 ===

func _ready() -> void:
	# 尝试自动获取依赖
	if _vehicle_type_db == null:
		_vehicle_type_db = VehicleTypeDB
	if _global_signals == null:
		_global_signals = GlobalSignals

## 设置依赖注入（用于测试）
func set_dependencies(vehicle_type_db: Object, global_signals: Object) -> void:
	_vehicle_type_db = vehicle_type_db
	_global_signals = global_signals

## 从 VehicleTypeDB 初始化战车属性
func initialize(p_vehicle_id: int) -> void:
	vehicle_id = p_vehicle_id

	if _vehicle_type_db == null:
		push_warning("[VehicleAttribute] VehicleTypeDB not set, using defaults")
		_use_default_values()
		return

	var stats: Object = _vehicle_type_db.get_vehicle_stats(vehicle_id)
	if stats == null:
		push_warning("[VehicleAttribute] Invalid vehicle_id=%d, using defaults" % vehicle_id)
		_use_default_values()
		return

	max_health = stats.max_health
	max_magic = stats.magic_pool
	current_health = max_health
	current_magic = max_magic
	_current_state = VehicleTypeDB.VehicleState.DEPLOYED

	print("[VehicleAttribute] Initialized vehicle_id=%d, max_health=%.1f, max_magic=%.1f" % [vehicle_id, max_health, max_magic])

func _use_default_values() -> void:
	max_health = 100.0
	max_magic = 100.0
	current_health = max_health
	current_magic = max_magic
	_current_state = VehicleTypeDB.VehicleState.DEPLOYED

# === 查询 API ===

## 获取耐久度比例 (health/max_health)
## 返回 0.0 ~ 1.0 的比例值
func get_durability_ratio() -> float:
	if max_health <= 0.0:
		return 0.0
	return clamp(current_health / max_health, 0.0, 1.0)

## 获取魔能比例 (current_magic/max_magic)
## 返回 0.0 ~ 1.0 的比例值
func get_magic_energy_ratio() -> float:
	if max_magic <= 0.0:
		return 0.0
	return clamp(current_magic / max_magic, 0.0, 1.0)

## 获取当前状态
func get_current_state() -> int:
	return _current_state

## 检查是否魔能耗尽
func is_magic_depleted() -> bool:
	return get_magic_energy_ratio() < MAGIC_DEPLETION_THRESHOLD

## 检查是否可以消耗指定魔能
func can_afford_magic(amount: float) -> bool:
	return current_magic >= amount

# === 状态修改 ===

## 受到伤害
## 计算有效伤害，更新生命值，发射信号
func take_damage(amount: float) -> void:
	if amount <= 0.0:
		return

	var old_ratio: float = get_durability_ratio()
	current_health = max(current_health - amount, 0.0)
	var new_ratio: float = get_durability_ratio()

	# 发射局部信号
	emit_signal("health_changed", current_health, max_health)

	# 发射全局信号
	if _global_signals != null:
		_global_signals.vehicle_damaged.emit(amount)

	# 检查状态转换
	_check_state_transition(old_ratio, new_ratio)

	print("[VehicleAttribute] Damage=%.1f, health=%.1f/%.1f, ratio=%.2f" % [amount, current_health, max_health, new_ratio])

## 消耗魔能
## 返回 true 表示成功消耗，false 表示魔能不足
func consume_magic(amount: float) -> bool:
	if amount <= 0.0:
		return true

	if current_magic < amount:
		return false

	# 检查消耗前是否已经耗尽
	var was_depleted: bool = is_magic_depleted()

	current_magic -= amount

	# 发射局部信号
	emit_signal("magic_changed", current_magic, max_magic)

	# 发射全局信号
	if _global_signals != null:
		_global_signals.magic_pool_changed.emit(current_magic, max_magic)

		# 检查是否刚刚进入耗尽状态 (TR-magic-002)
		if not was_depleted and is_magic_depleted():
			_global_signals.magic_depleted.emit()

	print("[VehicleAttribute] Magic consumed=%.1f, remaining=%.1f/%.1f" % [amount, current_magic, max_magic])
	return true

## 恢复魔能
func replenish_magic(amount: float) -> void:
	if amount <= 0.0:
		return

	current_magic = min(current_magic + amount, max_magic)

	# 发射局部信号
	emit_signal("magic_changed", current_magic, max_magic)

	# 发射全局信号
	if _global_signals != null:
		_global_signals.magic_pool_changed.emit(current_magic, max_magic)

	print("[VehicleAttribute] Magic replenished=%.1f, current=%.1f/%.1f" % [amount, current_magic, max_magic])

## 恢复生命值
func repair(amount: float) -> void:
	if amount <= 0.0:
		return

	var old_ratio: float = get_durability_ratio()
	current_health = min(current_health + amount, max_health)
	var new_ratio: float = get_durability_ratio()

	# 发射局部信号
	emit_signal("health_changed", current_health, max_health)

	# 检查状态转换（修复可能从 DISABLED 恢复到 DEPLOYED）
	_check_state_transition(old_ratio, new_ratio)

	print("[VehicleAttribute] Repaired=%.1f, health=%.1f/%.1f" % [amount, current_health, max_health])

# === 状态转换 ===

func _check_state_transition(old_ratio: float, new_ratio: float) -> void:
	var old_state: int = _current_state
	var new_state: int = _calculate_state_from_ratio(new_ratio)

	# 如果状态未变化，直接返回
	if new_state == old_state:
		return

	# 检查是否允许转换
	if _vehicle_type_db != null:
		if not _vehicle_type_db.can_transition(old_state, new_state):
			push_warning("[VehicleAttribute] Invalid state transition: %d -> %d" % [old_state, new_state])
			return

	_current_state = new_state

	# 发射局部信号
	emit_signal("state_changed", new_state)

	# 发射全局信号
	if _global_signals != null:
		_global_signals.vehicle_state_changed.emit(new_state)

	# 特殊处理：被摧毁
	if new_state == VehicleTypeDB.VehicleState.DESTROYED:
		if _global_signals != null:
			_global_signals.vehicle_destroyed.emit(vehicle_id)

	print("[VehicleAttribute] State changed: %d -> %d" % [old_state, new_state])

func _calculate_state_from_ratio(ratio: float) -> int:
	if ratio <= DESTROYED_HEALTH_THRESHOLD:
		return VehicleTypeDB.VehicleState.DESTROYED
	elif ratio < DISABLED_HEALTH_THRESHOLD:
		return VehicleTypeDB.VehicleState.DISABLED
	else:
		return VehicleTypeDB.VehicleState.DEPLOYED

# === 测试辅助方法 ===

## 设置生命值（仅用于测试）
func set_health_for_test(value: float) -> void:
	current_health = clamp(value, 0.0, max_health)

## 设置魔能（仅用于测试）
func set_magic_for_test(value: float) -> void:
	current_magic = clamp(value, 0.0, max_magic)

## 设置状态（仅用于测试）
func set_state_for_test(state: int) -> void:
	_current_state = state