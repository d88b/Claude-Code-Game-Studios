# spawn_system_test.gd
# 尸潮生成系统测试 — content-004
## 尸潮生成系统测试
## 验证波次生成逻辑、敌人数量控制、状态转换
## QA Plan: production/qa/qa-plan-sprint-5-2026-04-26.md

extends GutTest

# === 测试目标 ===
const SPAWN_MANAGER_PATH: String = "res://src/spawn/spawn_manager.gd"

# === 常量引用 ===
var MAX_ACTIVE_ENEMIES: int = 100
var BASE_SPAWN_COUNT: int = 10
var WAVE_COUNT_PER_TIDE: int = 5
var WAVE_INTERVAL: float = 30.0
var SPAWN_INTERVAL_BASE: float = 0.1
var CELL_SIZE: int = 32

# === 测试实例 ===
var spawn_manager: Node = null

func before_each() -> void:
	var script: GDScript = load(SPAWN_MANAGER_PATH)
	spawn_manager = script.new()
	spawn_manager.is_initialized = true

func after_each() -> void:
	if spawn_manager != null and is_instance_valid(spawn_manager):
		spawn_manager.queue_free()
	spawn_manager = null

# === 波次计数测试 ===

## 测试波次数量递增
func test_wave_count_progression() -> void:
	spawn_manager.current_spawn_config = {
		"enemy_types": [1, 4, 5, 6, 8],
		"base_count": BASE_SPAWN_COUNT,
		"wave_count": WAVE_COUNT_PER_TIDE,
		"spawn_zone": spawn_manager.default_spawn_zone
	}

	# 波次 1: base_count * 1 / 5 = 2
	spawn_manager.current_wave_index = 0
	spawn_manager._start_next_wave()
	assert_eq(spawn_manager.current_wave_index, 1, "Wave index should be 1 after first wave")

	# 波次 2: base_count * 2 / 5 = 4
	spawn_manager.current_wave_index = 1
	spawn_manager._start_next_wave()
	assert_eq(spawn_manager.current_wave_index, 2, "Wave index should be 2 after second wave")

## 测试波次敌人数量计算
func test_wave_enemy_count_calculation() -> void:
	spawn_manager.current_spawn_config = {
		"base_count": 10,
		"wave_count": 5
	}

	# 波次 1: ceil(10 * 1 / 5) = 2
	spawn_manager.current_wave_index = 0
	spawn_manager._start_next_wave()
	var wave1_count: int = spawn_manager.wave_remaining
	assert_eq(wave1_count, 2, "Wave 1 should spawn 2 enemies")

	# 波次 5 (最后一波): ceil(10 * 5 / 5) = 10
	spawn_manager.current_wave_index = 4
	spawn_manager._start_next_wave()
	var wave5_count: int = spawn_manager.wave_remaining
	assert_eq(wave5_count, 10, "Wave 5 should spawn 10 enemies")

## 测试危险倍率影响
func test_danger_multiplier_effect() -> void:
	spawn_manager.current_spawn_config = {
		"base_count": 10,
		"wave_count": 5
	}

	# 无 TimeSystem 时，危险倍率默认 1.0
	spawn_manager._time_system = null
	spawn_manager.current_wave_index = 4
	spawn_manager._start_next_wave()

	# base_count * wave_index / wave_count = 10 * 5 / 5 = 10
	assert_eq(spawn_manager.wave_remaining, 10, "Without danger mult, wave 5 count is 10")

# === 敌人类型选择测试 ===

## 测试敌人类型列表
func test_enemy_type_list() -> void:
	spawn_manager.current_spawn_config = {
		"enemy_types": [1, 4, 5, 6, 8]
	}

	var types: Array = spawn_manager.current_spawn_config.get("enemy_types", [1])
	assert_eq(types.size(), 5, "Should have 5 enemy types")
	assert_true(1 in types, "Basic zombie (ID=1) should be in types")
	assert_true(8 in types, "Tank zombie (ID=8) should be in types")

## 测试敌人类型选择逻辑
func test_enemy_type_selection() -> void:
	spawn_manager.current_spawn_config = {
		"enemy_types": [1, 4, 5, 6, 8]
	}

	# 多次选择验证随机性
	var selected_types: Array[int] = []
	for i in range(20):
		var enemy_id: int = spawn_manager._select_enemy_type()
		selected_types.append(enemy_id)

	# 所有选择的类型都应该在配置列表中
	for enemy_id in selected_types:
		assert_true(enemy_id in [1, 4, 5, 6, 8], "Selected type should be in config")

## 测试空类型列表默认值
func test_empty_type_list_default() -> void:
	spawn_manager.current_spawn_config = {
		"enemy_types": []
	}

	var enemy_id: int = spawn_manager._select_enemy_type()
	assert_eq(enemy_id, 1, "Empty type list should default to enemy_id=1")

# === 活跃敌人上限测试 ===

## 测试活跃上限常量
func test_max_active_enemies_constant() -> void:
	assert_eq(spawn_manager.MAX_ACTIVE_ENEMIES, 100, "Max active enemies should be 100")

## 测试上限暂停生成
func test_spawn_pause_at_limit() -> void:
	# 模拟活跃敌人已达上限
	spawn_manager.current_state = spawn_manager.SpawnState.SPAWNING
	spawn_manager.wave_timer = 0.0
	spawn_manager.wave_remaining = 5

	# 创建模拟敌人列表
	for i in range(100):
		var mock_enemy: Node2D = Node2D.new()
		mock_enemy.name = "Enemy_%d" % i
		spawn_manager.active_enemy_list.append(mock_enemy)

	# 执行生成逻辑（应该暂停）
	spawn_manager._execute_spawning(0.016)

	# wave_remaining 应该不变（没有生成）
	assert_eq(spawn_manager.wave_remaining, 5, "Should not spawn when at limit")

	# 清理模拟敌人
	for enemy in spawn_manager.active_enemy_list:
		enemy.queue_free()

## 测试生成队列处理
func test_spawn_queue_processing() -> void:
	spawn_manager.active_enemy_list.clear()

	# 添加队列项
	spawn_manager.spawn_queue.append({"enemy_id": 1, "position": Vector2(100, 100)})
	spawn_manager.spawn_queue.append({"enemy_id": 4, "position": Vector2(200, 200)})

	# 模拟敌人死亡后释放名额
	spawn_manager._process_spawn_queue()

	# 队列应该减少
	assert_eq(spawn_manager.spawn_queue.size(), 0, "Queue should be processed when below limit")

# === 波次间隔测试 ===

## 测试波次间隔常量
func test_wave_interval_constant() -> void:
	assert_eq(spawn_manager.WAVE_INTERVAL, 30.0, "Wave interval should be 30 seconds")

## 测试波次计时器递减
func test_wave_timer_decrement() -> void:
	spawn_manager.current_state = spawn_manager.SpawnState.SPAWNING
	spawn_manager.wave_timer = 30.0
	spawn_manager.wave_remaining = 0  # 波次完成

	# 模拟帧更新
	spawn_manager._execute_spawning(1.0)
	assert_eq(spawn_manager.wave_timer, 29.0, "Wave timer should decrement")

## 测试生成间隔
func test_spawn_interval_constant() -> void:
	assert_eq(spawn_manager.SPAWN_INTERVAL_BASE, 0.1, "Spawn interval should be 0.1 seconds")

# === 状态转换测试 ===

## 测试状态枚举
func test_spawn_state_enum() -> void:
	assert_eq(spawn_manager.SpawnState.IDLE, 0, "IDLE state should be 0")
	assert_eq(spawn_manager.SpawnState.SPAWNING, 1, "SPAWNING state should be 1")
	assert_eq(spawn_manager.SpawnState.COMPLETE, 2, "COMPLETE state should be 2")

## 测试状态转换
func test_state_transition() -> void:
	spawn_manager.current_state = spawn_manager.SpawnState.IDLE
	spawn_manager._transition_to_state(spawn_manager.SpawnState.SPAWNING)

	assert_eq(spawn_manager.current_state, spawn_manager.SpawnState.SPAWNING, "State should be SPAWNING")

## 测试相同状态不转换
func test_same_state_no_transition() -> void:
	spawn_manager.current_state = spawn_manager.SpawnState.SPAWNING
	spawn_manager._transition_to_state(spawn_manager.SpawnState.SPAWNING)

	assert_eq(spawn_manager.current_state, spawn_manager.SpawnState.SPAWNING, "Same state should not change")

## 测试尸潮完成状态
func test_tide_complete_state() -> void:
	spawn_manager.current_spawn_config = {"wave_count": 5}
	spawn_manager.current_wave_index = 5

	spawn_manager._complete_wave()

	assert_eq(spawn_manager.current_state, spawn_manager.SpawnState.COMPLETE, "Should be COMPLETE after all waves")

# === 尸潮初始化测试 ===

## 测试尸潮启动
func test_start_tide() -> void:
	var config: Dictionary = {
		"enemy_types": [1, 4, 5, 6, 8],
		"base_count": 10,
		"wave_count": 5,
		"spawn_zone": spawn_manager.default_spawn_zone
	}

	spawn_manager.start_tide(config)

	assert_eq(spawn_manager.current_wave_index, 0, "Wave index should reset to 0")
	assert_eq(spawn_manager.total_spawned, 0, "Total spawned should reset to 0")
	assert_eq(spawn_manager.current_state, spawn_manager.SpawnState.SPAWNING, "Should be in SPAWNING state")

## 测试默认触发配置
func test_trigger_tide_default_config() -> void:
	spawn_manager._trigger_tide()

	assert_eq(spawn_manager.current_spawn_config.get("enemy_types").size(), 5, "Default config should have 5 enemy types")
	assert_eq(spawn_manager.current_spawn_config.get("base_count"), BASE_SPAWN_COUNT, "Default base_count should match constant")

# === 辅助功能测试 ===

## 测试获取活跃敌人数量
func test_get_active_count() -> void:
	spawn_manager.active_enemy_list.clear()

	# 添加 3 个模拟敌人
	for i in range(3):
		spawn_manager.active_enemy_list.append(Node2D.new())

	assert_eq(spawn_manager.get_active_count(), 3, "Active count should be 3")

	# 清理
	for enemy in spawn_manager.active_enemy_list:
		enemy.queue_free()

## 测试范围内敌人查询
func test_get_enemies_in_range() -> void:
	spawn_manager.active_enemy_list.clear()

	# 创建不同位置的敌人
	var enemy1: Node2D = Node2D.new()
	enemy1.position = Vector2(50, 50)
	spawn_manager.active_enemy_list.append(enemy1)

	var enemy2: Node2D = Node2D.new()
	enemy2.position = Vector2(200, 200)
	spawn_manager.active_enemy_list.append(enemy2)

	var enemy3: Node2D = Node2D.new()
	enemy3.position = Vector2(300, 300)
	spawn_manager.active_enemy_list.append(enemy3)

	# 查询中心点附近半径 100 内的敌人
	var nearby: Array = spawn_manager.get_enemies_in_range(Vector2(100, 100), 100.0)

	assert_eq(nearby.size(), 1, "Only enemy1 should be in range")
	assert_eq(nearby[0].position, Vector2(50, 50), "Nearby enemy should be at (50,50)")

	# 清理
	for enemy in spawn_manager.active_enemy_list:
		enemy.queue_free()

## 测试清理所有敌人
func test_clear_all_enemies() -> void:
	spawn_manager.active_enemy_list.clear()

	# 添加敌人
	for i in range(5):
		var enemy: Node2D = Node2D.new()
		enemy.position = Vector2(i * 100, 0)
		spawn_manager.active_enemy_list.append(enemy)

	# 清理
	spawn_manager.clear_all_enemies()

	assert_eq(spawn_manager.active_enemy_list.size(), 0, "Active list should be empty after clear")

# === 对象池测试 ===

## 测试对象池初始化
func test_enemy_pool_initialization() -> void:
	assert_eq(spawn_manager.POOL_INITIAL_SIZE, 25, "Pool initial size should be 25")

## 测试池大小常量
func test_pool_size_constant() -> void:
	var pool_size: int = spawn_manager._enemy_pool.size()
	# 池可能在 _ready 中初始化，这里只检查常量定义
	assert_true(spawn_manager.POOL_INITIAL_SIZE > 0, "Pool size constant should be positive")

# === 生成区域测试 ===

## 测试默认生成区域
func test_default_spawn_zone() -> void:
	var zone: Rect2i = spawn_manager.default_spawn_zone

	assert_eq(zone.position.x, -20, "Spawn zone starts at x=-20")
	assert_eq(zone.position.y, -10, "Spawn zone starts at y=-10")
	assert_eq(zone.size.x, 40, "Spawn zone width is 40")
	assert_eq(zone.size.y, 20, "Spawn zone height is 20")

## 测试位置有效性验证
func test_position_validity() -> void:
	spawn_manager.active_enemy_list.clear()

	# 添加一个敌人
	var enemy: Node2D = Node2D.new()
	enemy.position = Vector2(100, 100)
	spawn_manager.active_enemy_list.append(enemy)

	# 检查附近位置无效
	var nearby_pos: Vector2 = Vector2(110, 110)
	var is_valid: bool = spawn_manager._is_position_valid(nearby_pos)
	assert_false(is_valid, "Position near existing enemy should be invalid")

	# 检查远处位置有效
	var far_pos: Vector2 = Vector2(500, 500)
	is_valid = spawn_manager._is_position_valid(far_pos)
	assert_true(is_valid, "Position far from enemies should be valid")

	enemy.queue_free()

# === 边界测试 ===

## 测试零波次配置保护
func test_zero_wave_count_protection() -> void:
	spawn_manager.current_spawn_config = {
		"base_count": 10,
		"wave_count": 0  # 应该使用默认值 5
	}

	spawn_manager.current_wave_index = 0
	spawn_manager._start_next_wave()

	# wave_count=0 时，使用默认值 WAVE_COUNT_PER_TIDE=5
	# batch_count = ceil(10 * 1 / 5) = 2
	assert_eq(spawn_manager.wave_remaining, 2, "Zero wave_count should use default and spawn 2 enemies")

## 测试最大波次
func test_max_wave_index() -> void:
	spawn_manager.current_spawn_config = {
		"wave_count": 100
	}
	spawn_manager.current_wave_index = 100

	spawn_manager._complete_wave()

	# 应该完成尸潮而不是崩溃
	assert_eq(spawn_manager.current_state, spawn_manager.SpawnState.COMPLETE, "Should complete after max waves")

## 测试空配置默认值
func test_empty_config_defaults() -> void:
	spawn_manager.current_spawn_config = {}

	var base_count: int = spawn_manager.current_spawn_config.get("base_count", BASE_SPAWN_COUNT)
	var wave_count: int = spawn_manager.current_spawn_config.get("wave_count", WAVE_COUNT_PER_TIDE)

	assert_eq(base_count, BASE_SPAWN_COUNT, "Empty config should use default base_count")
	assert_eq(wave_count, WAVE_COUNT_PER_TIDE, "Empty config should use default wave_count")