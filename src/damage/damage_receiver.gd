# damage_receiver.gd
# DamageReceiver — 战车损坏接收系统
## DamageReceiver — 战车损坏接收系统
## 接收伤害事件，计算护甲减伤，扣除耐久值
## Core layer component (Story: damage-001)

class_name DamageReceiver extends Node

# === 常量 ===
## 最大护甲减伤比例 (80%)
const MAX_ARMOR_REDUCTION: float = 0.80
## 最小伤害保底 (防止完全无敌)
const MINIMUM_DAMAGE: int = 1
## 碰撞护甲有效系数 (碰撞伤害护甲减伤50%有效)
const COLLISION_ARMOR_EFFECTIVENESS: float = 0.50

# === 信号 ===
## 伤害接收信号 (source_type: int, raw_damage: float, actual_damage: float)
signal damage_received(source_type: int, raw_damage: float, actual_damage: float)
## 护甲有效反馈 (damage_blocked: float)
signal armor_effective(damage_blocked: float)

# === 伤害来源类型 ===
enum DamageSourceType {
	ENEMY_MELEE = 1,      ## 敌人近战攻击
	ENEMY_PROJECTILE = 2, ## 敌人远程投射物
	COLLISION_IMPACT = 3, ## 碰撞冲击
	SPECIAL_ATTACK = 4,   ## 特殊攻击
	ENVIRONMENT = 5       ## 环境伤害
}

# === 属性 ===
## 战车类型 ID
var vehicle_id: int = 1
## 护甲值 (从 VehicleTypeDB 获取)
var armor: float = 0.0

# === 依赖注入 ===
var _vehicle_attribute: Object = null
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
func set_dependencies(vehicle_attribute: Object, vehicle_type_db: Object, global_signals: Object) -> void:
	_vehicle_attribute = vehicle_attribute
	_vehicle_type_db = vehicle_type_db
	_global_signals = global_signals

## 从 VehicleTypeDB 初始化护甲值
func initialize(p_vehicle_id: int) -> void:
	vehicle_id = p_vehicle_id

	if _vehicle_type_db == null:
		push_warning("[DamageReceiver] VehicleTypeDB not set, using default armor=0")
		armor = 0.0
		return

	var stats: Object = _vehicle_type_db.get_vehicle_stats(vehicle_id)
	if stats == null:
		push_warning("[DamageReceiver] Invalid vehicle_id=%d, using default armor" % vehicle_id)
		armor = 0.0
		return

	armor = stats.armor
	print("[DamageReceiver] Initialized vehicle_id=%d, armor=%.1f" % [vehicle_id, armor])

# === 核心接口 ===

## 接收伤害
## source_type: DamageSourceType 枚举值
## raw_damage: 原始伤害值
## 返回实际造成的伤害值
func receive_damage(source_type: int, raw_damage: float) -> float:
	# 边界检查：零伤害跳过
	if raw_damage <= 0.0:
		return 0.0

	# 检查战车是否已瘫痪（无法接受伤害）
	if _is_vehicle_disabled():
		push_warning("[DamageReceiver] Damage rejected on disabled vehicle")
		return 0.0

	# 计算实际伤害
	var actual_damage: float = calculate_actual_damage(source_type, raw_damage)

	# 应用伤害到 VehicleAttribute
	if _vehicle_attribute != null:
		_vehicle_attribute.take_damage(actual_damage)
	elif _global_signals != null:
		# 如果没有 VehicleAttribute，直接发射信号
		_global_signals.vehicle_damaged.emit(actual_damage)

	# 发射局部信号
	emit_signal("damage_received", source_type, raw_damage, actual_damage)

	# 计算护甲阻挡值并发射反馈信号
	var damage_blocked: float = raw_damage - actual_damage
	if damage_blocked > 0.0:
		emit_signal("armor_effective", damage_blocked)

	print("[DamageReceiver] Damage received: source=%d, raw=%.1f, actual=%.1f, blocked=%.1f" % [source_type, raw_damage, actual_damage, damage_blocked])

	return actual_damage

## 计算实际伤害（应用护甲减伤）
func calculate_actual_damage(source_type: int, raw_damage: float) -> float:
	# 环境伤害绕过护甲
	if source_type == DamageSourceType.ENVIRONMENT:
		return max(raw_damage, MINIMUM_DAMAGE)

	# 特殊攻击可能绕过护甲（根据能力标志）
	# MVP简化：特殊攻击正常计算护甲
	# TODO: Alpha阶段添加 armor_pierce 标志检查

	# 计算护甲减伤比例
	var damage_reduction: float = _calculate_damage_reduction(source_type)

	# 计算实际伤害
	var actual_damage: float = raw_damage * (1.0 - damage_reduction)

	# 应用最小伤害保底
	return max(actual_damage, MINIMUM_DAMAGE)

## 计算护甲减伤比例
func _calculate_damage_reduction(source_type: int) -> float:
	var effective_armor: float = armor

	# 碰撞伤害护甲减伤50%有效
	if source_type == DamageSourceType.COLLISION_IMPACT:
		effective_armor = armor * COLLISION_ARMOR_EFFECTIVENESS

	# 计算减伤比例 (armor是百分比，0-80)
	var reduction: float = effective_armor / 100.0

	# Clamp 到最大减伤比例
	return min(reduction, MAX_ARMOR_REDUCTION)

## 检查战车是否已瘫痪
func _is_vehicle_disabled() -> bool:
	if _vehicle_attribute == null:
		return false

	var state: int = _vehicle_attribute.get_current_state()
	# DESTROYED (4) 或 DISABLED (3) 状态不接受伤害
	return state == VehicleTypeDB.VehicleState.DISABLED or state == VehicleTypeDB.VehicleState.DESTROYED

# === 辅助查询 ===

## 获取护甲值
func get_armor() -> float:
	return armor

## 获取最大护甲减伤比例
func get_max_armor_reduction() -> float:
	return MAX_ARMOR_REDUCTION

## 获取最小伤害保底
func get_minimum_damage() -> int:
	return MINIMUM_DAMAGE

# === 测试辅助 ===

## 设置护甲值（仅用于测试）
func set_armor_for_test(value: float) -> void:
	armor = value