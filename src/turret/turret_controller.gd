# turret_controller.gd
# TurretController — 炮塔自动射击系统
## TurretController — 炮塔自动射击系统
## 管理炮塔状态机、目标搜索、射击触发
## Core layer system (GDD turret-system.md)

class_name TurretController extends Node2D

# === 常量定义 (来自 GDD) ===
## 单元格尺寸
const CELL_SIZE: int = 32
## 最小伤害保底
const MINIMUM_DAMAGE: int = 1
## 目标搜索范围倍率
const TARGETING_RANGE_MULT: float = 2.0
## 护甲减伤系数
const TURRET_ARMOR_EFFECTIVENESS: float = 0.6
## 基础暴击概率
const TURRET_CRIT_CHANCE_BASE: float = 0.05
## 目标锁定帧数 (防抖)
const TARGET_LOCK_FRAMES: int = 3
## 损坏效率阈值
const DAMAGE_THRESHOLD: float = 0.5
## 严重损坏效率阈值
const HEAVY_DAMAGE_THRESHOLD: float = 0.3

# === 状态枚举 ===
enum TurretState {
	IDLE,       ## 待机 — 无目标
	TARGETING,  ## 瞄准 — 目标在搜索范围内
	FIRING,     ## 射击 — 执行射击
	COOLDOWN,   ## 冷却 — 等待冷却
	DISABLED    ## 损坏 — 停止运作
}

# === 目标优先级策略 ===
enum TargetingPriority {
	NEAREST,          ## 最近距离优先
	HIGHEST_THREAT,   ## 最高威胁优先
	LOWEST_HEALTH     ## 最低血量优先
}

# === 资源类型 ===
enum AmmoType {
	AMMO_STACK,       ## 弹药堆叠
	MAGIC_RESERVE,    ## 魔力储备
	FREE              ## 无消耗
}

# === 信号 ===
## 状态变化 (old_state: int, new_state: int)
signal turret_state_changed(old_state: int, new_state: int)
## 目标锁定 (target_id: int)
signal target_locked(target_id: int)
## 目标丢失 (reason: String)
signal target_lost(reason: String)
## 资源耗尽 (ammo_type: int)
signal resources_depleted(ammo_type: int)

# === 炮塔属性 (从 TurretTypeDB 加载) ===
## 炮塔 ID (建造物品 ID)
var turret_id: int = 200
## 实例 ID (运行时唯一)
var instance_id: int = 0
## 基础伤害
var damage: int = 20
## 射击速率 (发/秒)
var fire_rate: float = 2.0
## 攻击范围 (格)
var attack_range_cells: float = 15.0
## 攻击范围 (像素)
var attack_range: float = 480.0
## 目标搜索范围 (像素)
var targeting_range: float = 960.0
## 弹道速度 (格/秒)
var projectile_speed: float = 20.0
## 资源类型
var ammo_type: AmmoType = AmmoType.MAGIC_RESERVE
## 每发弹药消耗
var ammo_cost_per_shot: int = 1
## 每发魔力消耗
var magic_cost_per_shot: float = 5.0
## 旋转速度 (度/秒)
var rotation_speed: float = 90.0
## 目标优先级策略
var targeting_priority: TargetingPriority = TargetingPriority.NEAREST
## 最大弹药堆叠
var max_ammo: int = 60
## 最大魔力储备
var max_magic: float = 100.0
## 最大耐久
var max_health: int = 100

# === 状态变量 ===
## 当前状态
var current_state: TurretState = TurretState.IDLE
## 当前目标
var current_target: Node2D = null
## 冷却计时器
var cooldown_timer: float = 0.0
## 目标锁定帧数
var target_lock_frames: int = 0
## 当前弹药堆叠
var ammo_stack: int = 0
## 当前魔力储备
var magic_reserve: float = 100.0
## 当前耐久
var health: int = 100
## 效率系数
var efficiency: float = 1.0
## 暴击概率
var crit_chance: float = 0.05
## 炮塔朝向角度
var turret_angle: float = 0.0
## 是否已初始化
var is_initialized: bool = false

# === 依赖引用 ===
var _spawn_manager: Node = null
var _global_signals: Node = null
var _vehicle_attribute: Node = null

# === 初始化 ===

func _ready() -> void:
	_auto_find_dependencies()
	_apply_turret_defaults()

	print("[TurretController] Ready — turret_id=%d, damage=%d, fire_rate=%.1f" % [turret_id, damage, fire_rate])

func _process(delta: float) -> void:
	if not is_initialized:
		return

	# 损坏状态优先检查
	if health <= 0:
		_transition_to_state(TurretState.DISABLED)
		return

	# 更新冷却计时器
	_update_cooldown(delta)

	# 目标锁定帧数递减
	if target_lock_frames > 0:
		target_lock_frames -= 1
		return

	# 状态机执行
	_execute_state(delta)

## 自动查找依赖节点
func _auto_find_dependencies() -> void:
	if _spawn_manager == null:
		_spawn_manager = get_node_or_null("/root/SpawnManager")
	if _global_signals == null:
		_global_signals = get_node_or_null("/root/GlobalSignals")
	if _vehicle_attribute == null:
		_vehicle_attribute = get_node_or_null("/root/VehicleAttribute")

## 设置依赖注入 (用于测试)
func set_dependencies(spawn_manager: Node, global_signals: Node,
		vehicle_attribute: Node) -> void:
	_spawn_manager = spawn_manager
	_global_signals = global_signals
	_vehicle_attribute = vehicle_attribute
	is_initialized = true

## 应用炮塔默认参数 (MVP 内联)
func _apply_turret_defaults() -> void:
	# 基础炮塔 (turret_id = 200)
	match turret_id:
		200:  # 基础符文炮塔
			damage = 20
			fire_rate = 2.0
			attack_range_cells = 15.0
			attack_range = attack_range_cells * CELL_SIZE
			targeting_range = attack_range * TARGETING_RANGE_MULT
			projectile_speed = 20.0
			ammo_type = AmmoType.MAGIC_RESERVE
			magic_cost_per_shot = 5.0
			rotation_speed = 90.0
			targeting_priority = TargetingPriority.NEAREST
			max_ammo = 60
			max_magic = 100.0
			max_health = 100
			crit_chance = TURRET_CRIT_CHANCE_BASE
		201:  # 高速炮塔
			damage = 15
			fire_rate = 5.0
			attack_range_cells = 10.0
			attack_range = attack_range_cells * CELL_SIZE
			targeting_range = attack_range * TARGETING_RANGE_MULT
			projectile_speed = 30.0
			ammo_type = AmmoType.MAGIC_RESERVE
			magic_cost_per_shot = 3.0
			rotation_speed = 180.0
			targeting_priority = TargetingPriority.NEAREST
			max_magic = 80.0
			crit_chance = 0.10
		202:  # 重型炮塔
			damage = 40
			fire_rate = 1.0
			attack_range_cells = 20.0
			attack_range = attack_range_cells * CELL_SIZE
			targeting_range = attack_range * TARGETING_RANGE_MULT
			projectile_speed = 15.0
			ammo_type = AmmoType.AMMO_STACK
			ammo_cost_per_shot = 2
			rotation_speed = 45.0
			targeting_priority = TargetingPriority.HIGHEST_THREAT
			max_ammo = 30
			crit_chance = 0.15
		_:
			push_warning("[TurretController] Unknown turret_id=%d, using defaults" % turret_id)

	# 初始化资源
	ammo_stack = max_ammo
	magic_reserve = max_magic
	health = max_health

	is_initialized = true

## 初始化炮塔参数 (外部调用)
func initialize(p_turret_id: int) -> void:
	turret_id = p_turret_id
	_apply_turret_defaults()

# === 冷却更新 ===

func _update_cooldown(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer -= delta

# === 状态机执行 ===

func _execute_state(delta: float) -> void:
	match current_state:
		TurretState.IDLE:
			_execute_idle(delta)
		TurretState.TARGETING:
			_execute_targeting(delta)
		TurretState.FIRING:
			_execute_firing(delta)
		TurretState.COOLDOWN:
			_execute_cooldown(delta)
		TurretState.DISABLED:
			_execute_disabled(delta)

# === IDLE 状态 ===

func _execute_idle(delta: float) -> void:
	# 目标搜索
	var target: Node2D = _find_target()

	if target != null:
		current_target = target
		_transition_to_state(TurretState.TARGETING)
		target_locked.emit(target.enemy_id if target.has("enemy_id") else 0)

# === TARGETING 状态 ===

func _execute_targeting(delta: float) -> void:
	# 目标有效性检查
	if current_target == null or not is_instance_valid(current_target):
		_transition_to_state(TurretState.IDLE)
		target_lost.emit("目标无效")
		return

	# 目标距离检查
	var distance: float = position.distance_to(current_target.position)

	# 目标超出搜索范围
	if distance > targeting_range:
		_transition_to_state(TurretState.IDLE)
		target_lost.emit("超出范围")
		current_target = null
		return

	# 目标在攻击范围内且冷却完成
	if distance <= attack_range and cooldown_timer <= 0.0:
		# 资源检查
		if _check_resources():
			_transition_to_state(TurretState.FIRING)
		else:
			_transition_to_state(TurretState.IDLE)
			resources_depleted.emit(ammo_type)

# === FIRING 状态 ===

func _execute_firing(delta: float) -> void:
	# 执行射击
	_perform_fire()

	# 重置冷却
	cooldown_timer = 1.0 / fire_rate

	# 进入冷却状态
	_transition_to_state(TurretState.COOLDOWN)

## 执行射击
func _perform_fire() -> void:
	# 扣减资源
	_consume_resources()

	# 计算伤害
	var target_armor: float = 0.0
	if current_target.has("armor"):
		target_armor = current_target.armor

	var final_damage: int = _calculate_damage(target_armor)

	# 发射信号
	if _global_signals != null:
		_global_signals.turret_fired.emit(instance_id, position, position.direction_to(current_target.position))

		# 命中信号
		var target_id: int = current_target.enemy_id if current_target.has("enemy_id") else 0
		_global_signals.turret_hit.emit(instance_id, target_id, final_damage)

	print("[TurretController] Fired — damage=%d at target=%s" % [final_damage, current_target.name])

# === COOLDOWN 状态 ===

func _execute_cooldown(delta: float) -> void:
	# 冷却完成检查
	if cooldown_timer <= 0.0:
		# 检查目标是否仍有效
		if current_target != null and is_instance_valid(current_target):
			var distance: float = position.distance_to(current_target.position)
			if distance <= attack_range and _check_resources():
				_transition_to_state(TurretState.FIRING)
			elif distance <= targeting_range:
				_transition_to_state(TurretState.TARGETING)
			else:
				_transition_to_state(TurretState.IDLE)
				current_target = null
		else:
			_transition_to_state(TurretState.IDLE)
			current_target = null

# === DISABLED 状态 ===

func _execute_disabled(delta: float) -> void:
	# 停止运作
	current_target = null

# === 状态转换 ===

func _transition_to_state(new_state: TurretState) -> void:
	if current_state == new_state:
		return

	var old_state: TurretState = current_state
	current_state = new_state

	# 目标锁定帧数 (防抖)
	if new_state in [TurretState.TARGETING, TurretState.FIRING]:
		target_lock_frames = TARGET_LOCK_FRAMES

	turret_state_changed.emit(old_state, new_state)

	print("[TurretController] State transition: %d → %d" % [old_state, new_state])

# === 目标搜索 ===

func _find_target() -> Node2D:
	if _spawn_manager == null:
		return null

	var enemies: Array = _spawn_manager.get_active_enemies()

	if enemies.size() == 0:
		return null

	# 篦选射程内敌人
	var valid_targets: Array = []
	for enemy: Node2D in enemies:
		if not is_instance_valid(enemy):
			continue

		var distance: float = position.distance_to(enemy.position)
		if distance <= targeting_range:
			valid_targets.append({"enemy": enemy, "distance": distance})

	if valid_targets.size() == 0:
		return null

	# 排序策略
	match targeting_priority:
		TargetingPriority.NEAREST:
			valid_targets.sort_custom(func(a, b): return a.distance < b.distance)
		TargetingPriority.HIGHEST_THREAT:
			# WALL_BREAKER 威胁更高 (待实现)
			valid_targets.sort_custom(func(a, b): return a.distance < b.distance)
		TargetingPriority.LOWEST_HEALTH:
			valid_targets.sort_custom(func(a, b):
				var health_a: float = a.enemy.health if a.enemy.has("health") else INF
				var health_b: float = b.enemy.health if b.enemy.has("health") else INF
				return health_a < health_b)

	# 返回第一个有效目标
	return valid_targets[0].enemy

# === 资源管理 ===

## 检查资源是否足够
func _check_resources() -> bool:
	match ammo_type:
		AmmoType.AMMO_STACK:
			return ammo_stack >= ammo_cost_per_shot
		AmmoType.MAGIC_RESERVE:
			return magic_reserve >= magic_cost_per_shot
		AmmoType.FREE:
			return true

	return false

## 扣减资源
func _consume_resources() -> void:
	match ammo_type:
		AmmoType.AMMO_STACK:
			ammo_stack -= ammo_cost_per_shot
		AmmoType.MAGIC_RESERVE:
			magic_reserve -= magic_cost_per_shot
		AmmoType.FREE:
			pass  # 无消耗

# === 伤害计算 ===

func _calculate_damage(target_armor: float) -> int:
	# 暴击判定
	var crit_factor: float = 1.0
	if randf() < crit_chance:
		crit_factor = 2.0

	# 护甲减伤
	var armor_reduction: float = target_armor * TURRET_ARMOR_EFFECTIVENESS

	# 最终伤害
	var final_damage: float = damage * efficiency * crit_factor - armor_reduction

	return maxi(int(final_damage), MINIMUM_DAMAGE)

# === 损坏处理 ===

## 受到伤害
func take_damage(amount: int) -> void:
	health -= amount
	_update_efficiency()

	print("[TurretController] Took damage=%d, health=%d/%d" % [amount, health, max_health])

	if health <= 0:
		_transition_to_state(TurretState.DISABLED)

## 更新效率系数
func _update_efficiency() -> void:
	var health_ratio: float = float(health) / float(max_health)

	if health_ratio > DAMAGE_THRESHOLD:
		efficiency = 1.0
	elif health_ratio > HEAVY_DAMAGE_THRESHOLD:
		efficiency = 0.8
	else:
		efficiency = 0.5

## 修复
func repair(amount: int) -> void:
	health = mini(health + amount, max_health)
	_update_efficiency()

	if health > 0 and current_state == TurretState.DISABLED:
		_transition_to_state(TurretState.IDLE)

# === 公共 API ===

## 获取当前状态
func get_state() -> TurretState:
	return current_state

## 获取当前目标
func get_target() -> Node2D:
	return current_target

## 获取耐久比例
func get_health_ratio() -> float:
	return float(health) / float(max_health)

## 获取资源比例
func get_resource_ratio() -> float:
	match ammo_type:
		AmmoType.AMMO_STACK:
			return float(ammo_stack) / float(max_ammo)
		AmmoType.MAGIC_RESERVE:
			return magic_reserve / max_magic
		AmmoType.FREE:
			return 1.0

	return 0.0

## 补给弹药
func replenish_ammo(amount: int) -> void:
	if ammo_type == AmmoType.AMMO_STACK:
		ammo_stack = mini(ammo_stack + amount, max_ammo)

## 补给魔力
func replenish_magic(amount: float) -> void:
	if ammo_type == AmmoType.MAGIC_RESERVE:
		magic_reserve = mini(magic_reserve + amount, max_magic)

# === 测试辅助 ===

func set_state_for_test(state: TurretState) -> void:
	current_state = state
	target_lock_frames = 0

func set_target_for_test(target: Node2D) -> void:
	current_target = target

func set_cooldown_for_test(value: float) -> void:
	cooldown_timer = value

func set_health_for_test(value: int) -> void:
	health = value
	_update_efficiency()

func set_ammo_for_test(value: int) -> void:
	ammo_stack = value

func set_magic_for_test(value: float) -> void:
	magic_reserve = value

func set_position_for_test(pos: Vector2) -> void:
	position = pos