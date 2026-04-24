# enemy_ai_controller.gd
# EnemyAIController — 敌人 AI 状态机
## EnemyAIController — 敌人 AI 状态机
## 管理敌人行为决策、路径规划、攻击触发
## Core layer system (GDD enemy-ai-system.md, ADR-010)

class_name EnemyAIController extends CharacterBody2D

# === 常量定义 (来自 GDD) ===
## 检测范围倍率
const DETECTION_RANGE_MULT: float = 2.0
## 状态转换锁定帧数 (防抖)
const STATE_LOCK_FRAMES: int = 3
## 路径重算最大重试次数
const MAX_PATH_RETRIES: int = 3
## 追击速度倍率
const TRACKER_HUNT_SPEED_MULT: float = 1.5
## 追击类型路径重算间隔
const PATH_RECALC_INTERVAL_TRACKER: float = 0.1
## 标准类型路径重算间隔
const PATH_RECALC_INTERVAL_STANDARD: float = 0.5
## IDLE 超时时间
const IDLE_TIMEOUT: float = 5.0

# === 状态枚举 ===
enum EnemyState {
	IDLE,           ## 待机 — 无目标
	MOVE_TO_TARGET, ## 向目标移动
	ATTACK,         ## 攻击
	STUN,           ## 眩晕
	DEAD            ## 死亡
}

# === behavior_hint 扩展状态 ===
enum BehaviorState {
	NORMAL,         ## 无扩展状态
	BREAKING_WALL,  ## 拆墙 (WALL_BREAKER)
	HUNTING,        ## 追击 (TRACKER_HUNT)
	PATROLING,      ## 巡逻 (PATROL_GUARD)
	AIMING,         ## 瞄准 (SNIPER_RANGE)
	HIDING,         ## 隐藏 (AMBUSHER_HIDE)
	SUMMONING,      ## 召唤 (SUMMONER_CALL)
	BUFFING         ## 增强 (SUPPORT_BUFF)
}

# === 信号 ===
## 状态变化 (old_state: int, new_state: int)
signal state_changed(old_state: int, new_state: int)
## 攻击触发 (target: Node2D, damage: float)
signal attack_triggered(target: Node2D, damage: float)
## 目标丢失 (reason: String)
signal target_lost(reason: String)

# === 敌人属性 (从 EnemyTypeDB 加载) ===
	## 敌人类型 ID
	var enemy_id: int = 1
	## 阵营 (0=GRAVEYARD, 1=HELL, 2=TOWER, 3=ELEMENT)
	var faction: int = 0
	## 生命值
	var health: float = 50.0
## 伤害值
var damage: float = 10.0
## 护甲值
var armor: float = 0.0
## 移动速度 (像素/秒)
var base_speed: float = 100.0
## 行为提示
var behavior_hint: String = "aggressive"
## 攻击范围 (像素)
var attack_range: float = 32.0
## 攻击冷却时间 (秒)
var attack_cooldown: float = 1.0
## 检测范围 (像素)
var detection_range: float = 64.0

# === 状态变量 ===
## 当前状态
var current_state: EnemyState = EnemyState.IDLE
## 当前行为扩展状态
var behavior_state: BehaviorState = BehaviorState.NORMAL
## 状态锁定帧数
var state_lock_frames: int = 0
## 攻击计时器
var attack_timer: float = 0.0
## 路径重算计时器
var path_recalc_timer: float = 0.0
## IDLE 超时计时器
var idle_timer: float = 0.0
## 路径重试次数
var path_retry_count: int = 0
## 当前目标
var current_target: Node2D = null
## 目标位置缓存
var target_position_cache: Vector2 = Vector2.ZERO
## 是否已初始化
var is_initialized: bool = false
## 当前速度倍率
var speed_multiplier: float = 1.0

# === 依赖引用 ===
var _enemy_type_db: Node = null
var _vehicle_controller: Node = null
var _global_signals: Node = null
var _tilemap_world: Node = null

# === NavigationAgent2D 引用 ===
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

# === 初始化 ===

func _ready() -> void:
	_auto_find_dependencies()

	# 等待 NavigationAgent2D 初始化
	if nav_agent == null:
		push_error("[EnemyAIController] NavigationAgent2D NOT FOUND!")
		return

	# 配置 NavigationAgent2D 参数
	nav_agent.path_desired_distance = 10.0
	nav_agent.target_desired_distance = 10.0

	print("[EnemyAIController] Ready — enemy_id=%d, behavior=%s" % [enemy_id, behavior_hint])

func _physics_process(delta: float) -> void:
	if not is_initialized:
		return

	# 死亡状态优先检查
	if health <= 0.0:
		_transition_to_state(EnemyState.DEAD)
		return

	# 更新计时器
	_update_timers(delta)

	# 状态锁定检查
	if state_lock_frames > 0:
		state_lock_frames -= 1
		return

	# 状态机执行
	_execute_state(delta)

## 自动查找依赖节点
func _auto_find_dependencies() -> void:
	if _enemy_type_db == null:
		_enemy_type_db = get_node_or_null("/root/EnemyTypeDB")
	if _vehicle_controller == null:
		_vehicle_controller = get_node_or_null("/root/VehicleController")
	if _global_signals == null:
		_global_signals = get_node_or_null("/root/GlobalSignals")
	if _tilemap_world == null:
		_tilemap_world = get_node_or_null("/root/TileMapWorld")

## 设置依赖注入 (用于测试)
func set_dependencies(enemy_type_db: Node, vehicle_controller: Node,
		global_signals: Node, tilemap_world: Node) -> void:
	_enemy_type_db = enemy_type_db
	_vehicle_controller = vehicle_controller
	_global_signals = global_signals
	_tilemap_world = tilemap_world

## 初始化敌人参数 (从 EnemyTypeDB 加载)
func initialize(p_enemy_id: int) -> void:
	enemy_id = p_enemy_id

	if _enemy_type_db == null:
		push_warning("[EnemyAIController] EnemyTypeDB not found, using defaults")
		is_initialized = true
		return

	var stats: Object = _enemy_type_db.get_enemy_stats(enemy_id)
	if stats == null:
		push_warning("[EnemyAIController] Invalid enemy_id=%d, using defaults" % enemy_id)
		is_initialized = true
		return

	# 加载属性
	health = stats.health
	damage = stats.damage
	armor = stats.armor
	base_speed = stats.speed
	behavior_hint = stats.behavior_hint

	# 计算衍生属性
	attack_range = 32.0  # 默认 1 格
	detection_range = attack_range * DETECTION_RANGE_MULT
	attack_cooldown = 1.0

	# 应用 behavior_hint 速度倍率
	_apply_behavior_speed_multiplier()

	is_initialized = true
	print("[EnemyAIController] Initialized enemy_id=%d, health=%.1f, speed=%.1f, behavior=%s" % [enemy_id, health, base_speed, behavior_hint])

## 应用 behavior_hint 速度倍率
func _apply_behavior_speed_multiplier() -> void:
	speed_multiplier = 1.0

	# 追击类型速度倍率
	if behavior_hint == "tracker":
		speed_multiplier = TRACKER_HUNT_SPEED_MULT

# === 计时器更新 ===

func _update_timers(delta: float) -> void:
	# 攻击计时器递减
	if attack_timer > 0.0:
		attack_timer -= delta

	# 路径重算计时器递减
	if path_recalc_timer > 0.0:
		path_recalc_timer -= delta

	# IDLE 超时计时器
	if current_state == EnemyState.IDLE:
		idle_timer += delta

# === 状态机执行 ===

func _execute_state(delta: float) -> void:
	match current_state:
		EnemyState.IDLE:
			_execute_idle(delta)
		EnemyState.MOVE_TO_TARGET:
			_execute_move_to_target(delta)
		EnemyState.ATTACK:
			_execute_attack(delta)
		EnemyState.STUN:
			_execute_stun(delta)
		EnemyState.DEAD:
			_execute_dead(delta)

# === IDLE 状态 ===

func _execute_idle(delta: float) -> void:
	# IDLE 超时检查
	if idle_timer >= IDLE_TIMEOUT:
		# 保持 IDLE，重置计时器
		idle_timer = 0.0
		return

	# 目标检测
	var target: Node2D = _detect_target()
	if target != null:
		current_target = target
		_transition_to_state(EnemyState.MOVE_TO_TARGET)

# === MOVE_TO_TARGET 状态 ===

func _execute_move_to_target(delta: float) -> void:
	# 目标有效性检查
	if current_target == null or not is_instance_valid(current_target):
		_transition_to_state(EnemyState.IDLE)
		target_lost.emit("目标无效")
		return

	# 更新目标位置
	var target_pos: Vector2 = current_target.position

	# 路径重算检查
	if path_recalc_timer <= 0.0 or target_pos != target_position_cache:
		_recalculate_path(target_pos)
		target_position_cache = target_pos

		# 设置路径重算间隔
		if behavior_hint == "tracker":
			path_recalc_timer = PATH_RECALC_INTERVAL_TRACKER
		else:
			path_recalc_timer = PATH_RECALC_INTERVAL_STANDARD

	# 获取下一个路径点
	var next_pos: Vector2 = nav_agent.get_next_path_position()

	# 计算移动方向
	var direction: Vector2 = position.direction_to(next_pos)

	# 计算速度
	var current_speed: float = base_speed * speed_multiplier
	velocity = direction * current_speed

	# 应用移动
	move_and_slide()

	# 检查是否到达目标
	var distance: float = position.distance_to(target_pos)
	if distance <= attack_range and attack_timer <= 0.0:
		_transition_to_state(EnemyState.ATTACK)

# === ATTACK 状态 ===

func _execute_attack(delta: float) -> void:
	# 目标有效性检查
	if current_target == null or not is_instance_valid(current_target):
		_transition_to_state(EnemyState.IDLE)
		return

	# 执行攻击
	_perform_attack()

	# 重置攻击计时器
	attack_timer = attack_cooldown

	# 攻击后返回移动状态
	_transition_to_state(EnemyState.MOVE_TO_TARGET)

## 执行攻击
func _perform_attack() -> void:
	# 发射攻击信号
	attack_triggered.emit(current_target, damage)

	# 发射全局信号 (通过 EnemyDamageSystem 处理)
	if _global_signals != null:
		# enemy_killed 信号在敌人死亡时发射，攻击信号由伤害系统处理
		pass

	print("[EnemyAIController] Attack target=%s with damage=%.1f" % [current_target.name, damage])

# === STUN 状态 ===

func _execute_stun(delta: float) -> void:
	# STUN 状态不执行任何行动
	velocity = Vector2.ZERO

# === DEAD 状态 ===

func _execute_dead(delta: float) -> void:
		# 停止移动
		velocity = Vector2.ZERO

		# 触发死亡 VFX (阵营特定)
		_trigger_death_vfx()

		# 发射死亡信号
		if _global_signals != null:
			_global_signals.enemy_killed.emit(enemy_id)

		# 清理
		current_target = null

		print("[EnemyAIController] Enemy died — enemy_id=%d, faction=%d" % [enemy_id, faction])

	## 触发阵营特定死亡 VFX
	func _trigger_death_vfx() -> void:
		# 根据 faction 选择 VFX 效果
		# 0=GRAVEYARD: 有机崩溃 → 粘液扩散
		# 1=HELL: 维度消散 → 深渊吸入
		# 2=TOWER: 机械解体 → 锈蚀崩溃
		# 3=ELEMENT: 晶石粉碎 → 光芒消散
		# TODO: 实现具体 VFX (粒子/动画) — technical-artist
		print("[EnemyAIController] Death VFX triggered for faction=%d" % faction)

# === 状态转换 ===

func _transition_to_state(new_state: EnemyState) -> void:
	if current_state == new_state:
		return

	var old_state: EnemyState = current_state
	current_state = new_state

	# 状态锁定 (防抖)
	state_lock_frames = STATE_LOCK_FRAMES

	# 重置相关计时器
	if new_state == EnemyState.IDLE:
		idle_timer = 0.0
	elif new_state == EnemyState.MOVE_TO_TARGET:
		path_recalc_timer = 0.0

	# 发射状态变化信号
	state_changed.emit(old_state, new_state)

	print("[EnemyAIController] State transition: %d → %d" % [old_state, new_state])

# === 目标检测 ===

func _detect_target() -> Node2D:
	# 优先追踪战车 (tracker 类型)
	if behavior_hint == "tracker" and _vehicle_controller != null:
		if is_instance_valid(_vehicle_controller):
			return _vehicle_controller

	# 默认: 追踪战车
	if _vehicle_controller != null and is_instance_valid(_vehicle_controller):
		var distance: float = position.distance_to(_vehicle_controller.position)
		if distance <= detection_range:
			return _vehicle_controller

	return null

# === 路径规划 ===

func _recalculate_path(target_pos: Vector2) -> void:
	if nav_agent == null:
		push_warning("[EnemyAIController] NavigationAgent2D not available")
		return

	nav_agent.set_target_position(target_pos)

	# 检查路径是否可达
	if nav_agent.is_navigation_finished():
		path_retry_count += 1
		if path_retry_count >= MAX_PATH_RETRIES:
			push_warning("[EnemyAIController] Path unreachable for enemy_id=%d" % enemy_id)
			_transition_to_state(EnemyState.IDLE)
	else:
		path_retry_count = 0

# === 公共 API ===

## 获取当前状态
func get_current_state() -> EnemyState:
	return current_state

## 获取生命值
func get_health() -> float:
	return health

## 受到伤害
func take_damage(amount: float) -> void:
	# 护甲减伤
	var actual_damage: float = amount * (1.0 - armor / 100.0)
	health -= actual_damage

	print("[EnemyAIController] Took damage=%.1f, health=%.1f" % [actual_damage, health])

	if health <= 0.0:
		_transition_to_state(EnemyState.DEAD)

## 设置眩晕
func set_stun(duration: float) -> void:
	_transition_to_state(EnemyState.STUN)
	# STUN 状态持续时间由外部系统控制

## 强制设置状态 (用于测试)
func set_state_for_test(state: EnemyState) -> void:
	current_state = state
	state_lock_frames = 0

## 设置目标 (用于测试)
func set_target_for_test(target: Node2D) -> void:
	current_target = target

## 设置生命值 (用于测试)
func set_health_for_test(value: float) -> void:
	health = value

## 设置攻击计时器 (用于测试)
func set_attack_timer_for_test(value: float) -> void:
	attack_timer = value

## 设置位置 (用于测试)
func set_position_for_test(pos: Vector2) -> void:
	position = pos

# === 生命周期 ===

func _exit_tree() -> void:
	# 清理
	current_target = null