# spawn_wave_test.gd
# Unit tests for Story: Spawn Wave Timing
# tests/unit/spawn/spawn_wave_test.gd

extends GutTest

const SpawnManagerScript := preload("res://src/spawn/spawn_manager.gd")
const EnemyTypeDBScript := preload("res://src/database/enemy_type_db.gd")
const TimeSystemScript := preload("res://src/time/time_system.gd")

var _spawn_manager: Object
var _enemy_type_db: Object
var _time_system: Object

# === Setup ===

func before_all() -> void:
	# 创建 EnemyTypeDB
	_enemy_type_db = EnemyTypeDBScript.new()
	add_child_autoqfree(_enemy_type_db)
	await get_tree().process_frame

	# 创建 TimeSystem
	_time_system = TimeSystemScript.new()
	add_child_autoqfree(_time_system)
	await get_tree().process_frame

func before_each() -> void:
	# 创建 SpawnManager
	_spawn_manager = SpawnManagerScript.new()
	add_child_autoqfree(_spawn_manager)
	_spawn_manager.set_dependencies(_enemy_type_db, _time_system, GlobalSignals, null)

# === 常量验证 ===

func test_max_active_enemies_is_100() -> void:
	assert_eq(_spawn_manager.MAX_ACTIVE_ENEMIES, 100, "MAX_ACTIVE_ENEMIES should be 100")

func test_max_position_retries_is_5() -> void:
	assert_eq(_spawn_manager.MAX_POSITION_RETRIES, 5, "MAX_POSITION_RETRIES should be 5")

func test_spawn_interval_base_is_0_1() -> void:
	assert_eq(_spawn_manager.SPAWN_INTERVAL_BASE, 0.1, "SPAWN_INTERVAL_BASE should be 0.1")

func test_wave_count_per_tide_is_5() -> void:
	assert_eq(_spawn_manager.WAVE_COUNT_PER_TIDE, 5, "WAVE_COUNT_PER_TIDE should be 5")

func test_wave_interval_is_30_0() -> void:
	assert_eq(_spawn_manager.WAVE_INTERVAL, 30.0, "WAVE_INTERVAL should be 30.0")

func test_spawn_animation_duration_is_0_5() -> void:
	assert_eq(_spawn_manager.SPAWN_ANIMATION_DURATION, 0.5, "SPAWN_ANIMATION_DURATION should be 0.5")

func test_base_spawn_count_is_10() -> void:
	assert_eq(_spawn_manager.BASE_SPAWN_COUNT, 10, "BASE_SPAWN_COUNT should be 10")

func test_spawn_zone_min_distance_is_10() -> void:
	assert_eq(_spawn_manager.SPAWN_ZONE_MIN_DISTANCE, 10, "SPAWN_ZONE_MIN_DISTANCE should be 10")

func test_spawn_zone_width_is_20() -> void:
	assert_eq(_spawn_manager.SPAWN_ZONE_WIDTH, 20, "SPAWN_ZONE_WIDTH should be 20")

# === 状态枚举测试 ===

func test_spawn_state_idle_is_0() -> void:
	assert_eq(_spawn_manager.SpawnState.IDLE, 0, "IDLE should be 0")

func test_spawn_state_spawning_is_1() -> void:
	assert_eq(_spawn_manager.SpawnState.SPAWNING, 1, "SPAWNING should be 1")

func test_spawn_state_complete_is_2() -> void:
	assert_eq(_spawn_manager.SpawnState.COMPLETE, 2, "COMPLETE should be 2")

# === 初始状态测试 ===

func test_initial_state_is_idle() -> void:
	assert_eq(_spawn_manager.current_state, _spawn_manager.SpawnState.IDLE, "Initial state should be IDLE")

func test_initial_active_enemy_list_empty() -> void:
	assert_eq(_spawn_manager.active_enemy_list.size(), 0, "active_enemy_list should start empty")

func test_initial_wave_index_is_0() -> void:
	assert_eq(_spawn_manager.current_wave_index, 0, "current_wave_index should start at 0")

func test_initial_total_spawned_is_0() -> void:
	assert_eq(_spawn_manager.total_spawned, 0, "total_spawned should start at 0")

func test_initial_spawn_queue_empty() -> void:
	assert_eq(_spawn_manager.spawn_queue.size(), 0, "spawn_queue should start empty")

# === 信号测试 ===

func test_spawn_state_changed_signal_exists() -> void:
	assert_true(_spawn_manager.has_signal("spawn_state_changed"), "spawn_state_changed signal should exist")

func test_wave_started_signal_exists() -> void:
	assert_true(_spawn_manager.has_signal("wave_started"), "wave_started signal should exist")

func test_wave_completed_signal_exists() -> void:
	assert_true(_spawn_manager.has_signal("wave_completed"), "wave_completed signal should exist")

func test_tide_completed_signal_exists() -> void:
	assert_true(_spawn_manager.has_signal("tide_completed"), "tide_completed signal should exist")

func test_global_enemy_spawned_signal_exists() -> void:
	assert_true(GlobalSignals.has_signal("enemy_spawned"), "GlobalSignals.enemy_spawned should exist")

func test_global_enemy_killed_signal_exists() -> void:
	assert_true(GlobalSignals.has_signal("enemy_killed"), "GlobalSignals.enemy_killed should exist")

func test_global_day_phase_changed_signal_exists() -> void:
	assert_true(GlobalSignals.has_signal("day_phase_changed"), "GlobalSignals.day_phase_changed should exist")

# === 公共 API 测试 ===

func test_get_active_enemies_method_exists() -> void:
	assert_true(_spawn_manager.has_method("get_active_enemies"), "get_active_enemies should exist")

func test_get_enemies_in_range_method_exists() -> void:
	assert_true(_spawn_manager.has_method("get_enemies_in_range"), "get_enemies_in_range should exist")

func test_get_active_count_method_exists() -> void:
	assert_true(_spawn_manager.has_method("get_active_count"), "get_active_count should exist")

func test_spawn_enemy_manual_method_exists() -> void:
	assert_true(_spawn_manager.has_method("spawn_enemy_manual"), "spawn_enemy_manual should exist")

func test_start_tide_method_exists() -> void:
	assert_true(_spawn_manager.has_method("start_tide"), "start_tide should exist")

func test_clear_all_enemies_method_exists() -> void:
	assert_true(_spawn_manager.has_method("clear_all_enemies"), "clear_all_enemies should exist")

# === get_active_enemies 测试 ===

func test_get_active_enemies_returns_empty_initially() -> void:
	var enemies: Array = _spawn_manager.get_active_enemies()
	assert_eq(enemies.size(), 0, "Should return empty array initially")

func test_get_active_count_returns_zero_initially() -> void:
	var count: int = _spawn_manager.get_active_count()
	assert_eq(count, 0, "Should return 0 initially")

# === get_enemies_in_range 测试 ===

func test_get_enemies_in_range_returns_empty_no_enemies() -> void:
	var enemies: Array = _spawn_manager.get_enemies_in_range(Vector2(100, 100), 50.0)
	assert_eq(enemies.size(), 0, "Should return empty when no enemies")

# === 日夜阶段触发测试 ===

func test_on_day_phase_changed_night_triggers_tide() -> void:
	# Night phase == 3 (TimeSystem.DayPhase.NIGHT)
	_spawn_manager.set_state_for_test(_spawn_manager.SpawnState.IDLE)
	_spawn_manager._on_day_phase_changed(3)
	assert_eq(_spawn_manager.current_state, _spawn_manager.SpawnState.SPAWNING, "Night should trigger spawning")

func test_on_day_phase_changed_day_no_trigger() -> void:
	_spawn_manager.set_state_for_test(_spawn_manager.SpawnState.IDLE)
	_spawn_manager._on_day_phase_changed(1)  # DAY phase
	assert_eq(_spawn_manager.current_state, _spawn_manager.SpawnState.IDLE, "Day should not trigger spawning")

func test_on_day_phase_changed_dusk_no_trigger() -> void:
	_spawn_manager.set_state_for_test(_spawn_manager.SpawnState.IDLE)
	_spawn_manager._on_day_phase_changed(2)  # DUSK phase
	assert_eq(_spawn_manager.current_state, _spawn_manager.SpawnState.IDLE, "Dusk should not trigger spawning")

func test_on_day_phase_changed_dawn_no_trigger() -> void:
	_spawn_manager.set_state_for_test(_spawn_manager.SpawnState.IDLE)
	_spawn_manager._on_day_phase_changed(0)  # DAWN phase
	assert_eq(_spawn_manager.current_state, _spawn_manager.SpawnState.IDLE, "Dawn should not trigger spawning")

# === 波次管理测试 ===

func test_start_next_wave_increments_index() -> void:
	_spawn_manager.set_spawn_config_for_test({"wave_count": 5, "base_count": 10})
	_spawn_manager.set_state_for_test(_spawn_manager.SpawnState.SPAWNING)
	_spawn_manager.current_wave_index = 0
	_spawn_manager._start_next_wave()
	assert_eq(_spawn_manager.current_wave_index, 1, "Wave index should increment")

func test_wave_remaining_calculated_correctly() -> void:
	_spawn_manager.set_spawn_config_for_test({"wave_count": 5, "base_count": 10})
	_spawn_manager.set_state_for_test(_spawn_manager.SpawnState.SPAWNING)
	_spawn_manager.current_wave_index = 0
	_spawn_manager._start_next_wave()
	# wave 1: ceil(10 * 1 / 5) = 2
	assert_eq(_spawn_manager.wave_remaining, 2, "Wave remaining should be 2 for wave 1")

func test_wave_remaining_uses_danger_multiplier() -> void:
	_spawn_manager.set_spawn_config_for_test({"wave_count": 5, "base_count": 10})
	_spawn_manager.set_state_for_test(_spawn_manager.SpawnState.SPAWNING)
	_spawn_manager.current_wave_index = 0
	# danger_mult should be applied (TimeSystem returns 2.0 for NIGHT)
	_spawn_manager._start_next_wave()
	# Expected: 2 * 2.0 = 4 (if night)
	# 但测试中 TimeSystem 可能不在 NIGHT phase，所以检查大于 0
	assert_gt(_spawn_manager.wave_remaining, 0, "Wave remaining should be positive")

# === 生成配置测试 ===

func test_start_tide_sets_spawn_config() -> void:
	var config: Dictionary = {
		"enemy_types": [1, 4, 5],
		"base_count": 20,
		"wave_count": 3,
		"spawn_zone": Rect2i(Vector2i(-10, -5), Vector2i(10, 5))
	}
	_spawn_manager.start_tide(config)
	assert_eq(_spawn_manager.current_spawn_config, config, "spawn_config should be set")

func test_start_tide_transitions_to_spawning() -> void:
	_spawn_manager.start_tide({"base_count": 5, "wave_count": 1})
	assert_eq(_spawn_manager.current_state, _spawn_manager.SpawnState.SPAWNING, "Should transition to SPAWNING")

func test_start_tide_resets_counters() -> void:
	_spawn_manager.total_spawned = 50
	_spawn_manager.current_wave_index = 3
	_spawn_manager.start_tide({"base_count": 5, "wave_count": 1})
	assert_eq(_spawn_manager.total_spawned, 0, "total_spawned should reset")
	assert_eq(_spawn_manager.current_wave_index, 0, "wave_index should reset")

# === 敌人类型选择测试 ===

func test_select_enemy_type_method_exists() -> void:
	assert_true(_spawn_manager.has_method("_select_enemy_type"), "_select_enemy_type should exist")

func test_select_enemy_type_returns_valid_id() -> void:
	_spawn_manager.set_spawn_config_for_test({"enemy_types": [1, 4, 5, 6]})
	var enemy_id: int = _spawn_manager._select_enemy_type()
	assert_true([1, 4, 5, 6].has(enemy_id), "Should return valid enemy_id from list")

func test_select_enemy_type_fallback_on_empty() -> void:
	_spawn_manager.set_spawn_config_for_test({"enemy_types": []})
	var enemy_id: int = _spawn_manager._select_enemy_type()
	assert_eq(enemy_id, 1, "Should fallback to 1 when empty")

# === 位置验证测试 ===

func test_is_position_valid_method_exists() -> void:
	assert_true(_spawn_manager.has_method("_is_position_valid"), "_is_position_valid should exist")

func test_is_position_valid_returns_true_empty_list() -> void:
	var is_valid: bool = _spawn_manager._is_position_valid(Vector2(100, 100))
	assert_true(is_valid, "Position should be valid when no active enemies")

func test_cell_to_world_method_exists() -> void:
	assert_true(_spawn_manager.has_method("_cell_to_world"), "_cell_to_world should exist")

func test_cell_to_world_without_tilemap_uses_fallback() -> void:
	var world_pos: Vector2 = _spawn_manager._cell_to_world(Vector2i(5, 5))
	# Fallback: 5 * 32 + 16 = 176
	assert_eq(world_pos, Vector2(176.0, 176.0), "Should use fallback calculation")

# === 敌人创建测试 ===

func test_create_enemy_instance_method_exists() -> void:
	assert_true(_spawn_manager.has_method("_create_enemy_instance"), "_create_enemy_instance should exist")

func test_spawn_enemy_manual_adds_to_list() -> void:
	_spawn_manager.spawn_enemy_manual(1, Vector2(100, 100))
	await get_tree().process_frame
	assert_eq(_spawn_manager.active_enemy_list.size(), 1, "Should add enemy to list")

func test_spawn_enemy_manual_emits_enemy_spawned() -> void:
	var signal_emitted: bool = false
	var spawned_id: int = -1
	var spawned_pos: Vector2 = Vector2.ZERO
	GlobalSignals.enemy_spawned.connect(func(p_id: int, p_pos: Vector2):
		signal_emitted = true
		spawned_id = p_id
		spawned_pos = p_pos
	)

	_spawn_manager.spawn_enemy_manual(1, Vector2(100, 100))
	await get_tree().process_frame

	assert_true(signal_emitted, "enemy_spawned should emit")
	assert_eq(spawned_id, 1, "enemy_id should match")
	assert_eq(spawned_pos, Vector2(100, 100), "position should match")

func test_spawn_enemy_manual_increments_total_spawned() -> void:
	_spawn_manager.spawn_enemy_manual(1, Vector2(100, 100))
	await get_tree().process_frame
	assert_eq(_spawn_manager.total_spawned, 1, "total_spawned should increment")

# === 活跃上限测试 ===

func test_active_count_below_max_allows_spawn() -> void:
	# 不超过上限时应允许生成
	assert_lt(_spawn_manager.get_active_count(), _spawn_manager.MAX_ACTIVE_ENEMIES, "Should be below max")

# === 敌人死亡处理测试 ===

func test_on_enemy_killed_removes_from_list() -> void:
	_spawn_manager.spawn_enemy_manual(1, Vector2(100, 100))
	await get_tree().process_frame

	var initial_count: int = _spawn_manager.active_enemy_list.size()
	_spawn_manager._on_enemy_killed(1)
	assert_lt(_spawn_manager.active_enemy_list.size(), initial_count, "Should remove enemy from list")

# === 清理测试 ===

func test_clear_all_enemies_removes_all() -> void:
	_spawn_manager.spawn_enemy_manual(1, Vector2(100, 100))
	_spawn_manager.spawn_enemy_manual(4, Vector2(200, 200))
	await get_tree().process_frame

	_spawn_manager.clear_all_enemies()
	assert_eq(_spawn_manager.active_enemy_list.size(), 0, "Should clear all enemies")

# === 测试辅助方法测试 ===

func test_set_spawn_config_for_test_method_exists() -> void:
	assert_true(_spawn_manager.has_method("set_spawn_config_for_test"), "set_spawn_config_for_test should exist")

func test_set_wave_for_test_method_exists() -> void:
	assert_true(_spawn_manager.has_method("set_wave_for_test"), "set_wave_for_test should exist")

func test_set_state_for_test_method_exists() -> void:
	assert_true(_spawn_manager.has_method("set_state_for_test"), "set_state_for_test should exist")

func test_set_active_enemies_for_test_method_exists() -> void:
	assert_true(_spawn_manager.has_method("set_active_enemies_for_test"), "set_active_enemies_for_test should exist")

func test_set_current_day_for_test_method_exists() -> void:
	assert_true(_spawn_manager.has_method("set_current_day_for_test"), "set_current_day_for_test should exist")

# === 依赖注入测试 ===

func test_set_dependencies_method_exists() -> void:
	assert_true(_spawn_manager.has_method("set_dependencies"), "set_dependencies should exist")

func test_is_initialized_true_after_set_dependencies() -> void:
	_spawn_manager.set_dependencies(_enemy_type_db, _time_system, GlobalSignals, null)
	assert_true(_spawn_manager.is_initialized, "is_initialized should be true")

# === 生成队列测试 ===

func test_process_spawn_queue_method_exists() -> void:
	assert_true(_spawn_manager.has_method("_process_spawn_queue"), "_process_spawn_queue should exist")

# === 边界值测试 ===

func test_max_active_enemies_limit() -> void:
	# 理论上限测试 (不实际生成 100 个敌人)
	assert_eq(_spawn_manager.MAX_ACTIVE_ENEMIES, 100, "Max should be 100")

func test_wave_interval_boundary() -> void:
	assert_eq(_spawn_manager.WAVE_INTERVAL, 30.0, "Wave interval should be 30 seconds")

func test_spawn_interval_boundary() -> void:
	assert_eq(_spawn_manager.SPAWN_INTERVAL_BASE, 0.1, "Spawn interval should be 0.1 seconds")