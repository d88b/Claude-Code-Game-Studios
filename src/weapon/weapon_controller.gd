# weapon_controller.gd
# WeaponController — 战车武器发射控制
## WeaponController — 战车武器发射控制
## 管理 cooldown、魔能消耗检查、伤害计算、发射信号
## Core layer component (Story: weapon-001)

class_name WeaponController extends Node

# === 常量 ===
## 最小伤害保底
const MINIMUM_DAMAGE: int = 1
## 最大护甲减伤 (80%)
const MAX_ARMOR_REDUCTION: float = 0.80
## 射程衰减触发阈值比例 (80%射程后开始衰减)
const RANGE_FALLOFF_THRESHOLD: float = 0.80
## 最小射程衰减 (50%伤害保底)
const MIN_RANGE_FALLOFF: float = 0.50
## 武器切换冷却时间
const WEAPON_SWITCH_COOLDOWN: float = 0.5
## 瞄准死区
const AIM_DEADZONE: float = 0.15

# === 信号 ===
## 武器开火 (weapon_type_id: int, position: Vector2, direction: Vector2)
signal weapon_fired_local(weapon_type_id: int, position: Vector2, direction: Vector2)
## 武器命中 (weapon_type_id: int, target_id: int, damage: float)
signal weapon_hit_local(weapon_type_id: int, target_id: int, damage: float)
## 魔能不足射击失败 (required_cost: float)
signal magic_insufficient(required_cost: float)

# === 武器类型定义（内联 MVP）===
enum WeaponCategory { CANNON = 0, BEAM = 1, LAUNCHER = 2, SPECIAL = 3 }
enum FireMode { SINGLE = 0, BURST = 1, AUTO = 2 }
enum ProjectileType { DIRECT = 0, ARCING = 1, BEAM = 2, HOMING = 3 }

# === 武器属性 ===
## 武器类型 ID
var weapon_type_id: int = 1
## 基础伤害
var base_damage: float = 20.0
## 射击速率 (发/秒)
var fire_rate: float = 2.0
## 射击模式
var fire_mode: int = FireMode.SINGLE
## 最大射程 (格)
var range_cells: float = 15.0
## 每发魔能消耗
var magic_cost_per_shot: float = 10.0
## 弹道速度 (格/秒)
var projectile_speed: float = 20.0
## 精准度
var accuracy: float = 0.85
## 暴击概率
var crit_chance: float = 0.05
## 暴击倍率
var crit_multiplier: float = 2.0
## 效率修正 (改装加成)
var efficiency_modifier: float = 1.0

# === 状态 ===
## 当前 cooldown 剩余时间
var cooldown_timer: float = 0.0
## 武器切换 cooldown 剩余时间
var switch_cooldown_timer: float = 0.0
## 当前是否可射击
var is_ready_to_fire: bool = true
## 战车 ID (用于魔能消耗)
var vehicle_id: int = 1
## 当前位置 (发射起点)
var current_position: Vector2 = Vector2.ZERO
## 当前瞄准方向
var aim_direction: Vector2 = Vector2.RIGHT

# === 依赖注入 ===
var _vehicle_attribute: Object = null
var _global_signals: Object = null

# === 初始化 ===

func _ready() -> void:
	# 自动获取依赖
	if _global_signals == null:
		_global_signals = GlobalSignals

func _process(delta: float) -> void:
	# 更新 cooldown
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
		if cooldown_timer <= 0.0:
			cooldown_timer = 0.0
			is_ready_to_fire = true

	# 更新切换 cooldown
	if switch_cooldown_timer > 0.0:
		switch_cooldown_timer -= delta

## 设置依赖注入（用于测试）
func set_dependencies(vehicle_attribute: Object, global_signals: Object) -> void:
	_vehicle_attribute = vehicle_attribute
	_global_signals = global_signals

## 初始化武器参数
func initialize(p_weapon_type_id: int) -> void:
	weapon_type_id = p_weapon_type_id
	_apply_weapon_defaults(weapon_type_id)
	print("[WeaponController] Initialized weapon_id=%d, damage=%.1f, fire_rate=%.1f, magic_cost=%.1f" % [weapon_type_id, base_damage, fire_rate, magic_cost_per_shot])

## 应用武器默认参数（内联 MVP 武器类型）
func _apply_weapon_defaults(weapon_id: int) -> void:
	match weapon_id:
		1:  # 基础魔导炮
			base_damage = 20.0
			fire_rate = 2.0
			fire_mode = FireMode.SINGLE
			range_cells = 15.0
			magic_cost_per_shot = 10.0
			projectile_speed = 20.0
			accuracy = 0.85
			crit_chance = 0.05
			crit_multiplier = 2.0
		2:  # 高速符文炮
			base_damage = 10.0
			fire_rate = 5.0
			fire_mode = FireMode.BURST
			range_cells = 10.0
			magic_cost_per_shot = 5.0
			projectile_speed = 30.0
			accuracy = 0.90
			crit_chance = 0.10
			crit_multiplier = 1.5
		3:  # 晶石发射器
			base_damage = 40.0
			fire_rate = 1.0
			fire_mode = FireMode.SINGLE
			range_cells = 25.0
			magic_cost_per_shot = 20.0
			projectile_speed = 15.0
			accuracy = 0.75
			crit_chance = 0.15
			crit_multiplier = 2.5
		_:  # 默认
			push_warning("[WeaponController] Unknown weapon_id=%d, using defaults" % weapon_id)

# === 核心接口 ===

## 尝试射击
## 返回 true 表示射击成功，false 表示失败
func try_fire() -> bool:
	# 检查 cooldown
	if cooldown_timer > 0.0:
		return false

	# 检查切换 cooldown
	if switch_cooldown_timer > 0.0:
		return false

	# 检查魔能
	if not _check_magic_available():
		emit_signal("magic_insufficient", magic_cost_per_shot)
		return false

	# 执行射击
	_execute_fire()

	return true

## 检查魔能是否足够
func _check_magic_available() -> bool:
	if _vehicle_attribute == null:
		return true  # 无依赖时默认允许

	var current_magic: float = _vehicle_attribute.current_magic
	return current_magic >= magic_cost_per_shot

## 执行射击
func _execute_fire() -> void:
	# 扣除魔能
	if _vehicle_attribute != null:
		var success: bool = _vehicle_attribute.consume_magic(magic_cost_per_shot)
		if not success:
			push_warning("[WeaponController] Magic consume failed")
			return

	# 设置 cooldown
	cooldown_timer = 1.0 / fire_rate
	is_ready_to_fire = false

	# 发射信号
	emit_signal("weapon_fired_local", weapon_type_id, current_position, aim_direction)

	if _global_signals != null:
		_global_signals.turret_fired.emit(vehicle_id, current_position, aim_direction)
		_global_signals.weapon_fired.emit(weapon_type_id, current_position)

	print("[WeaponController] Fired weapon_id=%d at pos=(%.1f,%.1f) dir=(%.1f,%.1f)" % [weapon_type_id, current_position.x, current_position.y, aim_direction.x, aim_direction.y])

# === 伤害计算 ===

## 计算最终伤害
## target_armor: 目标护甲值 (百分比，0-80)
## distance: 弹道飞行距离 (格)
func calculate_damage(target_armor: float, distance: float = 0.0) -> float:
	# 计算暴击因子
	var crit_factor: float = _roll_crit()

	# 计算护甲减伤
	var armor_reduction: float = min(target_armor / 100.0, MAX_ARMOR_REDUCTION)

	# 计算射程衰减
	var range_falloff: float = _calculate_range_falloff(distance)

	# 计算最终伤害
	var final_damage: float = base_damage * efficiency_modifier * crit_factor * (1.0 - armor_reduction) * range_falloff

	# 应用最小伤害保底
	return max(final_damage, MINIMUM_DAMAGE)

## 暴击判定
func _roll_crit() -> float:
	if randf() < crit_chance:
		print("[WeaponController] CRITICAL HIT! crit_multiplier=%.1f" % crit_multiplier)
		return crit_multiplier
	return 1.0

## 计算射程衰减
func _calculate_range_falloff(distance: float) -> float:
	var threshold: float = range_cells * RANGE_FALLOFF_THRESHOLD

	# 在阈值内无衰减
	if distance <= threshold:
		return 1.0

	# 超过阈值计算衰减
	var falloff: float = 1.0 - (distance - threshold) / (range_cells - threshold) * (1.0 - MIN_RANGE_FALLOFF)

	# Clamp 到最小衰减
	return max(falloff, MIN_RANGE_FALLOFF)

# === 目标命中处理 ===

## 处理命中目标
## target_id: 目标 ID
## target_armor: 目标护甲
## distance: 命中时的飞行距离
func on_hit_target(target_id: int, target_armor: float, distance: float = 0.0) -> void:
	var damage: float = calculate_damage(target_armor, distance)

	# 发射命中信号
	emit_signal("weapon_hit_local", weapon_type_id, target_id, damage)

	if _global_signals != null:
		_global_signals.turret_hit.emit(vehicle_id, target_id, damage)

	print("[WeaponController] Hit target_id=%d with damage=%.1f (armor=%.1f, distance=%.1f)" % [target_id, damage, target_armor, distance])

# === 辅助接口 ===

## 获取 cooldown 剩余时间
func get_cooldown_remaining() -> float:
	return cooldown_timer

## 获取 cooldown 持续时间
func get_cooldown_duration() -> float:
	return 1.0 / fire_rate

## 检查是否可射击
func can_fire() -> bool:
	return cooldown_timer <= 0.0 and switch_cooldown_timer <= 0.0 and _check_magic_available()

## 获取魔能消耗
func get_magic_cost() -> float:
	return magic_cost_per_shot

## 获取射程
func get_range() -> float:
	return range_cells

## 获取基础伤害
func get_base_damage() -> float:
	return base_damage

## 设置位置（发射起点）
func set_position(pos: Vector2) -> void:
	current_position = pos

## 设置瞄准方向
func set_aim_direction(direction: Vector2) -> void:
	# 死区检查
	if direction.length() < AIM_DEADZONE:
		return
	aim_direction = direction.normalized()

# === 测试辅助 ===

## 设置 cooldown（仅用于测试）
func set_cooldown_for_test(value: float) -> void:
	cooldown_timer = value
	is_ready_to_fire = value <= 0.0

## 设置魔能消耗（仅用于测试）
func set_magic_cost_for_test(value: float) -> void:
	magic_cost_per_shot = value

## 设置暴击概率（仅用于测试）
func set_crit_chance_for_test(value: float) -> void:
	crit_chance = value

## 强制暴击（仅用于测试）
func force_crit_for_test() -> void:
	crit_chance = 1.0

## 禁用暴击（仅用于测试）
func disable_crit_for_test() -> void:
	crit_chance = 0.0