# spawn_manager.gd
# SpawnManager — 敌人生成系统
## SpawnManager — 敌人生成系统
## 管理敌人实例创建、生成波次、活跃敌人列表
## Core layer system (GDD enemy-spawn-system.md, ADR-002)

class_name SpawnManager extends Node

# === 常量定义 (来自 GDD) ===
## 最大活跃敌人数量
const MAX_ACTIVE_ENEMIES: int = 100
## 生成位置最大重试次数
const MAX_POSITION_RETRIES: int = 5
## 基础生成间隔 (秒)
const SPAWN_INTERVAL_BASE: float = 0.1
## 每次尸潮波次数量
const WAVE_COUNT_PER_TIDE: int = 5
## 波次间隔 (秒)
const WAVE_INTERVAL: float = 30.0
## 生成动画时长 (秒)
const SPAWN_ANIMATION_DURATION: float = 0.5
## 基础每波生成数量
const BASE_SPAWN_COUNT: int = 10
## 生成区域最小距离 (格)
const SPAWN_ZONE_MIN_DISTANCE: int = 10
## 生成区域宽度 (格)
	const SPAWN_ZONE_WIDTH: int = 20
	## 对象池初始大小 (预实例化敌人数量)
	const POOL_INITIAL_SIZE: int = 25

# === 状态枚举 ===
enum SpawnState {
	IDLE,       ## 待机 — 无生成请求
	SPAWNING,   ## 正在生成 — 执行批量生成
	COMPLETE    ## 生成完成 — 等待下一请求
}

# === 信号 ===
## 状态变化 (old_state: int, new_state: int)
signal spawn_state_changed(old_state: int, new_state: int)
## 波次开始 (wave_index: int, enemy_count: int)
signal wave_started(wave_index: int, enemy_count: int)
## 波次完成 (wave_index: int)
signal wave_completed(wave_index: int)
## 尸潮完成 (total_spawned: int)
signal tide_completed(total_spawned: int)

# === 状态变量 ===
## 当前状态
var current_state: SpawnState = SpawnState.IDLE
## 活跃敌人列表
var active_enemy_list: Array[Node2D] = []
## 当前波次索引
var current_wave_index: int = 0
## 当前波次剩余敌人
var wave_remaining: int = 0
## 生成计时器
var spawn_timer: float = 0.0
## 波次计时器
var wave_timer: float = 0.0
## 总已生成数量
var total_spawned: int = 0
## 当前生成配置
var current_spawn_config: Dictionary = {}
## 生成队列 (超出上限时缓存)
var spawn_queue: Array[Dictionary] = []
## 是否已初始化
var is_initialized: bool = false
## 当前天数 (用于 unlock_day 检查)
	var current_day: int = 0
	## 对象池 (待使用敌人)
	var _enemy_pool: Array[Node2D] = []

# === 生成区域定义 (MVP 固定值) ===
## 默认生成区域 (屏幕边缘)
var default_spawn_zone: Rect2i = Rect2i(Vector2i(-20, -10), Vector2i(20, 10))

# === 依赖引用 ===
var _enemy_type_db: Node = null
var _time_system: Node = null
var _global_signals: Node = null
var _tilemap_world: Node = null
var _enemy_scene: PackedScene = null

# === 初始化 ===

func _ready() -> void:
		_auto_find_dependencies()
		_load_enemy_scene()
		_initialize_enemy_pool()
		_connect_signals()

		print("[SpawnManager] initialized — MAX_ACTIVE_ENEMIES=", MAX_ACTIVE_ENEMIES, " pool_size=", POOL_INITIAL_SIZE)

## 自动查找依赖节点
func _auto_find_dependencies() -> void:
	if _enemy_type_db == null:
		_enemy_type_db = get_node_or_null("/root/EnemyTypeDB")
	if _time_system == null:
		_time_system = get_node_or_null("/root/TimeSystem")
	if _global_signals == null:
		_global_signals = get_node_or_null("/root/GlobalSignals")
	if _tilemap_world == null:
		_tilemap_world = get_node_or_null("/root/TileMapWorld")

## 加载敌人场景预制体
	func _load_enemy_scene() -> void:
		_enemy_scene = load("res://src/ai/enemy_ai_controller.tscn")  # 延迟加载兼容 headless
		if _enemy_scene == null:
			push_error("[SpawnManager] Failed to load enemy scene!")

	## 初始化敌人对象池 (性能优化)
	func _initialize_enemy_pool() -> void:
		if _enemy_scene == null:
			return

		for i: int in range(POOL_INITIAL_SIZE):
			var enemy: Node2D = _enemy_scene.instantiate()
			enemy.set_process(false)  # 禁用处理，池中待用
			_enemy_pool.append(enemy)

		print("[SpawnManager] Pool initialized — %d enemies pre-instantiated" % POOL_INITIAL_SIZE)

	## 从池中获取敌人 (或新建)
	func _get_enemy_from_pool() -> Node2D:
		if _enemy_pool.size() > 0:
			var enemy: Node2D = _enemy_pool.pop_back()
			enemy.set_process(true)  # 启用处理
			return enemy

		# 池空时新建
		var new_enemy: Node2D = _enemy_scene.instantiate()
		return new_enemy

	## 返回敌人到池中
	func _return_enemy_to_pool(enemy: Node2D) -> void:
		enemy.set_process(false)  # 禁用处理
		# 重置敌人状态
		if enemy.has_method("reset"):
			enemy.reset()
		_enemy_pool.append(enemy)

	## 连接全局信号
func _connect_signals() -> void:
	if _global_signals == null:
		return

	# 监听日夜阶段变化
	if _global_signals.has_signal("day_phase_changed"):
		_global_signals.day_phase_changed.connect(_on_day_phase_changed)

	# 监听敌人死亡
	if _global_signals.has_signal("enemy_killed"):
		_global_signals.enemy_killed.connect(_on_enemy_killed)

	# 监听天数变化
	if _global_signals.has_signal("day_count_changed"):
		_global_signals.day_count_changed.connect(_on_day_count_changed)

## 设置依赖注入 (用于测试)
func set_dependencies(enemy_type_db: Node, time_system: Node,
		global_signals: Node, tilemap_world: Node) -> void:
	_enemy_type_db = enemy_type_db
	_time_system = time_system
	_global_signals = global_signals
	_tilemap_world = tilemap_world
	_connect_signals()
	is_initialized = true

# === 信号处理 ===

## 日夜阶段变化处理
func _on_day_phase_changed(phase: int) -> void:
	# TimeSystem.DayPhase.NIGHT == 3
	if phase == 3:  # NIGHT
		_trigger_tide()

## 敌人死亡处理
	func _on_enemy_killed(enemy_id: int) -> void:
		# 从活跃列表移除并返回池中 (通过 enemy_id 匹配)
		for enemy: Node2D in active_enemy_list:
			if enemy.enemy_id == enemy_id:
				active_enemy_list.erase(enemy)
				_return_enemy_to_pool(enemy)  # 返回池中 (性能优化)
				break

		# 检查队列中是否有待生成敌人
		_process_spawn_queue()

## 天数变化处理
func _on_day_count_changed(day: int) -> void:
	current_day = day

# === 尸潮触发 ===

## 触发尸潮生成
func _trigger_tide() -> void:
	# 生成默认配置
	var spawn_config: Dictionary = {
		"enemy_types": [1, 4, 5, 6],  # 普通僵尸、集群、拆墙、追踪
		"base_count": BASE_SPAWN_COUNT,
		"wave_count": WAVE_COUNT_PER_TIDE,
		"spawn_zone": default_spawn_zone
	}

	start_tide(spawn_config)

## 开始尸潮生成
func start_tide(spawn_config: Dictionary) -> void:
	current_spawn_config = spawn_config
	current_wave_index = 0
	total_spawned = 0
	wave_timer = 0.0

	_transition_to_state(SpawnState.SPAWNING)
	_start_next_wave()

# === 波次管理 ===

## 开始下一波次
func _start_next_wave() -> void:
	current_wave_index += 1

	# 计算本波次生成数量
	var base_count: int = current_spawn_config.get("base_count", BASE_SPAWN_COUNT)
	var wave_count: int = current_spawn_config.get("wave_count", WAVE_COUNT_PER_TIDE)
	var batch_count: int = ceili(base_count * current_wave_index / wave_count)

	# 危险倍率 (夜晚更高)
	var danger_mult: float = 1.0
	if _time_system != null:
		danger_mult = _time_system.get_danger_multiplier()

	batch_count = int(batch_count * danger_mult)

	wave_remaining = batch_count
	spawn_timer = 0.0

	wave_started.emit(current_wave_index, batch_count)
	print("[SpawnManager] Wave %d started — %d enemies" % [current_wave_index, batch_count])

## 完成当前波次
func _complete_wave() -> void:
	wave_completed.emit(current_wave_index)

	# 检查是否还有下一波
	var wave_count: int = current_spawn_config.get("wave_count", WAVE_COUNT_PER_TIDE)
	if current_wave_index < wave_count:
		# 等待波次间隔
		wave_timer = WAVE_INTERVAL
	else:
		# 尸潮完成
		_transition_to_state(SpawnState.COMPLETE)
		tide_completed.emit(total_spawned)
		print("[SpawnManager] Tide completed — %d total spawned" % total_spawned)

# === 生成执行 ===

func _process(delta: float) -> void:
	if current_state == SpawnState.SPAWNING:
		_execute_spawning(delta)

## 执行生成逻辑
func _execute_spawning(delta: float) -> void:
	# 波次间隔检查
	if wave_timer > 0.0:
		wave_timer -= delta
		return

	# 活跃上限检查
	if active_enemy_list.size() >= MAX_ACTIVE_ENEMIES:
		# 暂停生成，等待敌人死亡释放名额
		return

	# 生成间隔计时
	spawn_timer -= delta
	if spawn_timer > 0.0:
		return

	# 执行生成
	if wave_remaining > 0:
		_spawn_single_enemy()
		wave_remaining -= 1
		spawn_timer = SPAWN_INTERVAL_BASE

	# 检查波次完成
	if wave_remaining <= 0:
		_complete_wave()

## 生成单个敌人
func _spawn_single_enemy() -> void:
	# 选择敌人类型
	var enemy_id: int = _select_enemy_type()

	# 选择生成位置
	var spawn_pos: Vector2 = _get_valid_spawn_position()

	# 创建敌人实例
	_create_enemy_instance(enemy_id, spawn_pos)

## 选择敌人类型 (加权随机)
func _select_enemy_type() -> int:
	var enemy_types: Array = current_spawn_config.get("enemy_types", [1])

	if enemy_types.size() == 0:
		return 1  # 默认类型

	# 简化 MVP: 随机选择 (加权随机可扩展)
	var index: int = randi() % enemy_types.size()
	return enemy_types[index]

## 获取有效生成位置
func _get_valid_spawn_position() -> Vector2:
	var spawn_zone: Rect2i = current_spawn_config.get("spawn_zone", default_spawn_zone)

	# 随机位置重试
	for retry: int in range(MAX_POSITION_RETRIES):
		var cell: Vector2i = Vector2i(
			randi_range(spawn_zone.position.x, spawn_zone.position.x + spawn_zone.size.x),
			randi_range(spawn_zone.position.y, spawn_zone.position.y + spawn_zone.size.y)
		)

		# 坐标转换
		var world_pos: Vector2 = _cell_to_world(cell)

		# 位置验证 (简化 MVP: 不检查墙体)
		if _is_position_valid(world_pos):
			return world_pos

	# Fallback: 使用区域中心
	return _cell_to_world(spawn_zone.position + spawn_zone.size / 2)

## Cell → World 坐标转换
func _cell_to_world(cell: Vector2i) -> Vector2:
	if _tilemap_world != null and _tilemap_world.has_method("map_to_local"):
		return _tilemap_world.map_to_local(cell)

	# Fallback: 直接计算 (32 像素/格)
	return Vector2(cell.x * 32.0 + 16.0, cell.y * 32.0 + 16.0)

## 位置有效性验证
func _is_position_valid(pos: Vector2) -> bool:
	# MVP 简化: 检查是否在活跃敌人位置附近
	for enemy: Node2D in active_enemy_list:
		if pos.distance_to(enemy.position) < 32.0:  # 1 格距离
			return false

	return true

## 创建敌人实例
func _create_enemy_instance(enemy_id: int, spawn_pos: Vector2) -> void:
	if _enemy_scene == null:
		push_error("[SpawnManager] Enemy scene not loaded!")
		return

	# 从池获取敌人 (性能优化)
	var enemy: Node2D = _get_enemy_from_pool()

	# 设置位置
	enemy.position = spawn_pos

	# 初始化敌人
	if enemy.has_method("initialize"):
		enemy.initialize(enemy_id)

	# 添加到场景 (如果不在场景中)
	if not enemy.is_inside_tree():
		add_child(enemy)

	# 添加到活跃列表
	active_enemy_list.append(enemy)
	total_spawned += 1

	# 发射生成信号
	if _global_signals != null:
		_global_signals.enemy_spawned.emit(enemy_id, spawn_pos)

			# Elite/Boss 敌人额外发射警告信号
			var enemy_tier: int = 0
			if _enemy_type_db != null:
				enemy_tier = _enemy_type_db.get_enemy_tier(enemy_id)
			if enemy_tier >= 2:  # Elite (2) or Boss (3)
				_global_signals.elite_spawned.emit(enemy_id, enemy_tier)

	print("[SpawnManager] Spawned enemy_id=%d at pos=(%.1f,%.1f) — active=%d, pool=%d" % [enemy_id, spawn_pos.x, spawn_pos.y, active_enemy_list.size(), _enemy_pool.size()])

# === 生成队列处理 ===

func _process_spawn_queue() -> void:
	if spawn_queue.size() == 0:
		return

	if active_enemy_list.size() < MAX_ACTIVE_ENEMIES:
		var next_spawn: Dictionary = spawn_queue.pop_front()
		_create_enemy_instance(next_spawn.enemy_id, next_spawn.position)

# === 状态转换 ===

func _transition_to_state(new_state: SpawnState) -> void:
	if current_state == new_state:
		return

	var old_state: SpawnState = current_state
	current_state = new_state

	spawn_state_changed.emit(old_state, new_state)
	print("[SpawnManager] State transition: %d → %d" % [old_state, new_state])

# === 公共 API ===

## 获取活跃敌人列表
func get_active_enemies() -> Array[Node2D]:
	return active_enemy_list

## 获取范围内的敌人
func get_enemies_in_range(center: Vector2, radius: float) -> Array[Node2D]:
	var result: Array[Node2D] = []

	for enemy: Node2D in active_enemy_list:
		if is_instance_valid(enemy):
			var distance: float = center.distance_to(enemy.position)
			if distance <= radius:
				result.append(enemy)

	return result

## 获取活跃敌人数量
func get_active_count() -> int:
	return active_enemy_list.size()

## 手动触发生成 (用于测试)
func spawn_enemy_manual(enemy_id: int, position: Vector2) -> void:
	_create_enemy_instance(enemy_id, position)

## 设置生成配置 (用于测试)
func set_spawn_config_for_test(config: Dictionary) -> void:
	current_spawn_config = config

## 设置当前波次 (用于测试)
func set_wave_for_test(wave_index: int, remaining: int) -> void:
	current_wave_index = wave_index
	wave_remaining = remaining

## 设置状态 (用于测试)
func set_state_for_test(state: SpawnState) -> void:
	current_state = state

## 设置活跃敌人列表 (用于测试)
func set_active_enemies_for_test(enemies: Array[Node2D]) -> void:
	active_enemy_list = enemies

## 设置当前天数 (用于测试)
func set_current_day_for_test(day: int) -> void:
	current_day = day

## 强制清理所有敌人 (用于测试)
	func clear_all_enemies() -> void:
		# 返回活跃敌人到池中
		for enemy: Node2D in active_enemy_list:
			if is_instance_valid(enemy):
				_return_enemy_to_pool(enemy)
		active_enemy_list.clear()

		# 清理池中敌人 (完整清理时)
		for enemy: Node2D in _enemy_pool:
			if is_instance_valid(enemy):
				enemy.queue_free()
		_enemy_pool.clear()

# === 生命周期 ===

func _exit_tree() -> void:
	# 清理所有敌人
	clear_all_enemies()