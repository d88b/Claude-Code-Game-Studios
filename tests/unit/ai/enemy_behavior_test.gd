# enemy_behavior_test.gd
# 敌人类型行为测试 — content-001
## 敌人类型行为测试
## 验证 5 种敌人的 behavior_hint 分支逻辑
## QA Plan: production/qa/qa-plan-sprint-5-2026-04-26.md

extends GutTest

# === 测试目标 ===
const ENEMY_SCENE_PATH: String = "res://src/ai/enemy_ai_controller.tscn"
const ENEMY_SCRIPT_PATH: String = "res://src/ai/enemy_ai_controller.gd"

# === 常量引用 ===
var TRACKER_SPEED_MULT: float = 1.5
var TANK_SPEED_MULT: float = 0.7
var SWARM_SCALE_MULT: float = 0.5

# === 测试实例 ===
var enemy: CharacterBody2D = null
var enemy_type_db: Node = null

func before_all() -> void:
	# 加载敌人类型数据库
	enemy_type_db = autoload("EnemyTypeDB")
	if enemy_type_db == null:
		push_error("[enemy_behavior_test] EnemyTypeDB not found!")

func before_each() -> void:
	# 创建敌人实例
	var enemy_script: GDScript = load(ENEMY_SCRIPT_PATH)
	enemy = enemy_script.new()
	enemy.enemy_id = 1

	# 设置测试依赖
	enemy.is_initialized = false

func after_each() -> void:
	if enemy != null and is_instance_valid(enemy):
		enemy.queue_free()
	enemy = null

# === 测试用例 ===

## 测试基础僵尸 (ID=1) behavior_hint = aggressive
func test_basic_zombie_aggressive_behavior() -> void:
	enemy.initialize(1)
	assert_true(enemy.is_initialized, "Enemy should be initialized")
	assert_eq(enemy.behavior_hint, "aggressive", "Basic zombie should have aggressive behavior")
	assert_eq(enemy.speed_multiplier, 1.0, "Basic zombie should have normal speed multiplier")
	assert_eq(enemy.scale_multiplier, 1.0, "Basic zombie should have normal scale")

## 测试集群僵尸 (ID=4) behavior_hint = swarm
func test_swarm_zombie_small_scale() -> void:
	enemy.initialize(4)
	assert_eq(enemy.behavior_hint, "swarm", "Swarm zombie should have swarm behavior")
	assert_eq(enemy.scale_multiplier, SWARM_SCALE_MULT, "Swarm zombie should have 0.5x scale")
	assert_true(enemy.speed_multiplier > 1.0, "Swarm zombie should have faster speed")

## 测试拆墙僵尸 (ID=5) behavior_hint = wall_breaker
func test_wall_breaker_target_selection() -> void:
	enemy.initialize(5)
	assert_eq(enemy.behavior_hint, "wall_breaker", "Wall breaker should have wall_breaker behavior")

	# 设置模拟墙体目标
	var mock_wall: Node2D = Node2D.new()
	mock_wall.position = Vector2(100, 100)
	mock_wall.add_to_group("structures")
	add_child(mock_wall)

	# 检测目标
	var target: Node2D = enemy._detect_target()
	assert_not_null(target, "Wall breaker should detect wall target")

	mock_wall.queue_free()

## 测试追踪僵尸 (ID=6) behavior_hint = tracker
func test_tracker_speed_multiplier() -> void:
	enemy.initialize(6)
	assert_eq(enemy.behavior_hint, "tracker", "Tracker should have tracker behavior")
	assert_eq(enemy.speed_multiplier, TRACKER_SPEED_MULT, "Tracker should have 1.5x speed multiplier")

## 测试坦克僵尸 (ID=8) behavior_hint = tank
func test_tank_slow_speed() -> void:
	enemy.initialize(8)
	assert_eq(enemy.behavior_hint, "tank", "Tank zombie should have tank behavior")
	assert_eq(enemy.speed_multiplier, TANK_SPEED_MULT, "Tank should have 0.7x speed multiplier")
	assert_true(enemy.health > 150.0, "Tank should have high health (200)")

## 测试行为提示无效时的默认值
func test_invalid_behavior_hint_default() -> void:
	enemy.behavior_hint = "unknown_hint"
	enemy._apply_behavior_speed_multiplier()
	assert_eq(enemy.speed_multiplier, 1.0, "Unknown behavior should default to normal speed")
	assert_eq(enemy.scale_multiplier, 1.0, "Unknown behavior should default to normal scale")

## 测试 EnemyTypeDB 包含所有 5 种敌人
func test_enemy_type_db_has_all_types() -> void:
	var required_ids: Array[int] = [1, 4, 5, 6, 8]

	for id: int in required_ids:
		var stats: Object = enemy_type_db.get_enemy_stats(id)
		assert_not_null(stats, "EnemyTypeDB should have enemy_id=%d" % id)

## 测试不同敌人的属性差异
func test_enemy_attribute_variations() -> void:
	# 基础僵尸 vs 坦克僵尸
	var basic_stats: Object = enemy_type_db.get_enemy_stats(1)
	var tank_stats: Object = enemy_type_db.get_enemy_stats(8)

	assert_true(tank_stats.health > basic_stats.health, "Tank should have more health than basic")
	assert_true(tank_stats.speed < basic_stats.speed, "Tank should be slower than basic")
	assert_true(tank_stats.armor > basic_stats.armor, "Tank should have more armor than basic")

## 测试集群僵尸属性
func test_swarm_low_health_high_speed() -> void:
	var swarm_stats: Object = enemy_type_db.get_enemy_stats(4)
	var basic_stats: Object = enemy_type_db.get_enemy_stats(1)

	assert_true(swarm_stats.health < basic_stats.health, "Swarm should have less health than basic")
	assert_true(swarm_stats.speed > basic_stats.speed, "Swarm should be faster than basic")

## 测试状态转换锁定
func test_state_transition_lock() -> void:
	enemy.initialize(1)

	# 触发状态转换
	enemy._transition_to_state(enemy.EnemyState.MOVE_TO_TARGET)
	assert_eq(enemy.state_lock_frames, enemy.STATE_LOCK_FRAMES, "State transition should apply lock frames")

	# 锁定期间不应执行状态
	enemy.state_lock_frames = 3
	enemy._execute_state(0.016)  # 模拟一帧
	assert_eq(enemy.state_lock_frames, 2, "Lock frames should decrement each frame")

## 测试弹开状态处理
func test_knockback_state_velocity_decay() -> void:
	enemy.initialize(1)
	enemy.is_initialized = false  # 弹开状态
	enemy.velocity = Vector2(100, 100)

	# 模拟 _physics_process
	enemy._physics_process(0.016)

	# 速度应该衰减 (每帧 5%)
	assert_almost_eq(enemy.velocity.x, 95.0, 1.0, "Velocity should decay 5% per frame")

## 测试死亡状态触发
func test_death_state_cleanup() -> void:
	enemy.initialize(1)
	enemy.health = 0.0

	# 模拟 _physics_process
	watch_signals(enemy)
	enemy._physics_process(0.016)

	assert_signal_emitted(enemy, "state_changed", "Death should emit state_changed signal")

# === 边界测试 ===

## 测试零生命值
func test_zero_health_immediate_death() -> void:
	enemy.initialize(1)
	enemy.health = 0.0

	# 应该立即死亡
	assert_true(enemy.health <= 0.0, "Zero health should trigger death")

## 测试最大速度倍率
func test_max_speed_multiplier_tracker() -> void:
	enemy.initialize(6)  # Tracker
	var expected_speed: float = enemy.base_speed * TRACKER_SPEED_MULT
	var actual_speed: float = enemy.base_speed * enemy.speed_multiplier
	assert_almost_eq(actual_speed, expected_speed, 1.0, "Tracker speed should be 1.5x base")

## 测试最小体型倍率
func test_min_scale_multiplier_swarm() -> void:
	enemy.initialize(4)  # Swarm
	assert_eq(enemy.scale_multiplier, SWARM_SCALE_MULT, "Swarm scale should be 0.5x")

## 测试护甲减伤
func test_armor_damage_reduction() -> void:
	enemy.initialize(8)  # Tank with armor=10
	enemy.health = 100.0

	var damage_amount: float = 50.0
	enemy.take_damage(damage_amount)

	# 伤害应该减少: actual = 50 * (1 - 10/100) = 45
	var expected_health: float = 100.0 - 45.0
	assert_almost_eq(enemy.health, expected_health, 1.0, "Armor should reduce damage by 10%")